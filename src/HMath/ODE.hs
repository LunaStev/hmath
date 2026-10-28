-- SPDX-License-Identifier: MPL-2.0

-- | Checked real ODE/DAE integration. Fixed-step methods use the requested
-- grid. Adaptive methods have explicit tolerances, step bounds and work budgets.
-- Callbacks must be pure, total and retain the state dimension. Dense output
-- uses a cubic Hermite interpolant, independently of the integration method.
module HMath.ODE
    ( ODE, Method(..), ODEOptions(..), defaultODEOptions, Trajectory(..)
    , solveIVP, solveAdaptive, interpolateTrajectory, Event(..), EventDirection(..), locateEvents
    , solveBoundary, solveDAE, solveHamiltonian, HamiltonianMethod(..)
    , solveNystrom, sensitivities, equilibrium, phaseTrajectories, lyapunovExponents
    ) where

import Control.Monad (foldM)
import Data.List (transpose)
import HMath.Calculus (jacobian)
import HMath.Error (MathError(..))
import HMath.Matrix (Matrix, fromListChecked, toList)
import HMath.Matrix.LU (solve)
import HMath.ODE.Tableau

-- | Time and state callback, returning a derivative of exactly the same length.
type ODE = Double -> [Double] -> [Double]
-- | Explicit, multistep, implicit, and linearly implicit methods. RK45 is the
-- Cash-Karp 5(4) pair; DormandPrince is the Dormand-Prince 5(4) pair. Radau is
-- two-stage Radau IIA (order 3), BDF is order 2 with backward-Euler startup,
-- and Rosenbrock is linearly implicit Rosenbrock-Euler (order 1).
data Method = Euler | Heun | Midpoint | RK2 | RK4 | RK23 | RK45 | DormandPrince | DOP853
    | AdamsBashforth | AdamsMoulton | PredictorCorrector | BackwardEuler | BDF | Radau | Rosenbrock
    deriving (Eq, Show)
-- | Positive step bounds and tolerances; maximumSteps bounds accepted and
-- rejected attempts, and newtonIterations bounds each implicit correction.
data ODEOptions = ODEOptions
    { odeAbsoluteTolerance :: Double, odeRelativeTolerance :: Double
    , initialStep :: Double, minimumStep :: Double, maximumStep :: Double
    , maximumSteps :: Int, newtonIterations :: Int
    } deriving (Eq, Show)
-- | Conservative default adaptive settings for Double callbacks.
defaultODEOptions :: ODEOptions
defaultODEOptions = ODEOptions 1e-9 1e-7 1e-2 1e-12 0.1 100000 30
-- | Strictly monotonic time samples, states and endpoint derivatives. The
-- constructor is public for inspection; interpolation validates all dimensions.
data Trajectory = Trajectory
    { trajectoryTimes :: [Double], trajectoryStates :: [[Double]], trajectoryDerivatives :: [[Double]] }
    deriving (Eq, Show)

finite :: Double -> Bool
finite x=not(isNaN x||isInfinite x)
require :: Bool -> String -> Either MathError ()
require condition message=if condition then Right() else Left(InvalidArgument message)
checked :: [Double] -> Either MathError [Double]
checked xs=if all finite xs then Right xs else Left NonFiniteResult
add :: [Double] -> [Double] -> [Double]
add=zipWith(+)
scale :: Double -> [Double] -> [Double]
scale a=map(a*)
norm :: [Double] -> Double
norm xs=let m=maximum(0:map abs xs) in if m==0 then 0 else m*sqrt(sum[(x/m)^ (2::Int)|x<-xs])
evaluate :: ODE -> Double -> [Double] -> Either MathError [Double]
evaluate f t y=do
    require (finite t&&all finite y) "nonfinite ODE point"
    let result=f t y
    require (length result==length y) "ODE callback changed state dimension"
    checked result
validateOptions :: ODEOptions -> Either MathError ()
validateOptions o=require (all finite [odeAbsoluteTolerance o,odeRelativeTolerance o,initialStep o,minimumStep o,maximumStep o]
    &&odeAbsoluteTolerance o>0&&odeRelativeTolerance o>=0&&minimumStep o>0&&initialStep o>0
    &&maximumStep o>=minimumStep o&&maximumSteps o>0&&newtonIterations o>0) "invalid ODE options"

-- | Integrate on n equal panels. Multistep methods use genuine derivative
-- history; implicit methods use checked finite-difference Newton iterations.
solveIVP :: Method -> ODEOptions -> Int -> ODE -> Double -> Double -> [Double] -> Either MathError Trajectory
solveIVP method options panels f start end initial = do
    validateOptions options
    require (panels>0&&finite start&&finite end&&all finite initial) "invalid IVP grid or initial state"
    require (panels<=maximumSteps options) "IVP grid exceeds step budget"
    d0<-evaluate f start initial
    if start==end then Right(Trajectory[start][initial][d0]) else do
        let h=(end-start)/fromIntegral panels
            go i t y previous previousDerivative times states derivatives
                | i==panels=Right(Trajectory(reverse times)(reverse states)(reverse derivatives))
                | otherwise=do
                    let nextTime=if i+1==panels then end else start+fromIntegral(i+1)*h
                        dt=nextTime-t
                    require (nextTime/=t) "ODE grid step rounded away"
                    next<-case (method,previous,previousDerivative) of
                        (AdamsBashforth,_,Just oldD)->checked(add y(scale dt(zipWith(\a b->1.5*a-0.5*b) (derivatives!!0) oldD)))
                        (AdamsMoulton,_,_)->implicitStep options f t dt y Nothing True
                        (PredictorCorrector,_,Just oldD)->do
                            predicted<-checked(add y(scale dt(zipWith(\a b->1.5*a-0.5*b) (derivatives!!0) oldD)))
                            dn<-evaluate f nextTime predicted
                            checked(add y(scale(dt/2)(add (derivatives!!0) dn)))
                        (BDF,Just oldY,_)->implicitStep options f t dt y (Just oldY) False
                        (BDF,Nothing,_)->implicitStep options f t dt y Nothing False
                        _->fixedStep method options f t dt y
                    dn<-evaluate f nextTime next
                    go(i+1) nextTime next (Just y)(Just(derivatives!!0)) (nextTime:times)(next:states)(dn:derivatives)
        go 0 start initial Nothing Nothing [start][initial][d0]

-- | Adaptive explicit RK integration. Euler/Heun/Midpoint/RK4 use step-doubling
-- error estimates. RK23/RK45/DormandPrince/DOP853 use their embedded estimates.
-- Multistep and implicit methods require 'solveIVP' to preserve their grid/history.
solveAdaptive :: Method -> ODEOptions -> ODE -> Double -> Double -> [Double] -> Either MathError Trajectory
solveAdaptive method options f start end initial=do
    validateOptions options
    require (method `elem` [Euler,Heun,Midpoint,RK2,RK4,RK23,RK45,DormandPrince,DOP853]) "adaptive driver requires an explicit RK method"
    require (finite start&&finite end&&all finite initial) "invalid adaptive IVP"
    d0<-evaluate f start initial
    if start==end then Right(Trajectory[start][initial][d0]) else do
        let direction=if end>start then 1 else -1
            initialH=direction*min(maximumStep options)(max(minimumStep options)(initialStep options))
            go attempts t y h times states derivatives
                | direction*(end-t)<=0=Right(Trajectory(reverse times)(reverse states)(reverse derivatives))
                | attempts>=maximumSteps options=Left(NonConvergence "adaptive ODE" attempts)
                | otherwise=do
                    let dt=direction*min(abs h)(abs(end-t)); nextTime=if abs dt>=abs(end-t) then end else t+dt
                    require (nextTime/=t) "adaptive ODE step rounded away"
                    (candidate,errVector)<-oneStep method options f t dt y
                    let scaled=zipWith3(\e a b->abs e/(odeAbsoluteTolerance options+odeRelativeTolerance options*max(abs a)(abs b))) errVector y candidate
                        err=maximum(0:scaled)
                        factor=if err==0 then 5 else max 0.1(min 5(0.9*err**(-1/fromIntegral(methodOrder method))))
                        nextH=direction*min(maximumStep options)(max(minimumStep options)(abs dt*factor))
                    if not(finite err) then Left NonFiniteResult
                    else if err<=1 then do
                        dn<-evaluate f nextTime candidate
                        go(attempts+1) nextTime candidate nextH(nextTime:times)(candidate:states)(dn:derivatives)
                    else if abs dt<=minimumStep options then Left(NonConvergence "minimum ODE step" attempts)
                    else go(attempts+1) t y nextH times states derivatives
        go 0 start initial initialH[start][initial][d0]

methodOrder :: Method -> Int
methodOrder method=case method of Euler->2; Heun->3; Midpoint->3; RK2->3; RK4->5; RK23->3; RK45->5; DormandPrince->5; DOP853->8; _->2

-- Explicit Runge-Kutta stages share the same checked callback and accumulation.
stages :: ODE -> Double -> Double -> [Double] -> [Double] -> [[Double]] -> Either MathError [[Double]]
stages f t h y cs rows=foldM stage [] (zip cs rows)
    where stage known (c,coefficients)=do
            state<-checked(foldl add y [scale(h*a) k|(a,k)<-zip coefficients known])
            k<-evaluate f (t+c*h) state
            Right(known++[k])
combine :: Double -> [Double] -> [Double] -> [[Double]] -> Either MathError [Double]
combine h y weights ks=checked(foldl add y[scale(h*w) k|(w,k)<-zip weights ks])

oneStep :: Method -> ODEOptions -> ODE -> Double -> Double -> [Double] -> Either MathError ([Double],[Double])
oneStep method options f t h y
    | method `elem` [BackwardEuler,BDF,AdamsMoulton] = do z<-implicitStep options f t h y Nothing(method==AdamsMoulton); Right(z,replicate(length y)0)
    | method==Rosenbrock=do
        d<-evaluate f t y
        j<-jacobian (sqrt(2.220446049250313e-16)*max 1(norm y)) (f t) y
        let n=length y; values=toList j
        matrix<-fromListChecked n n [ (if i==k then 1 else 0)-h*values!!(i*n+k)|i<-[0..n-1],k<-[0..n-1]]
        delta<-solve matrix (scale h d)
        z<-checked(add y delta)
        Right(z,replicate n 0)
    | method==Radau=do
        d<-evaluate f t y
        let n=length y
            residual zs=let (k1,k2)=splitAt n zs; y1=add y(scale h(zipWith(\a b->5*a/12-b/12) k1 k2)); y2=add y(scale h(zipWith(\a b->3*a/4+b/4) k1 k2))
                            v1=f(t+h/3)y1; v2=f(t+h)y2
                        in if length v1/=n||length v2/=n then replicate(2*n)(0/0) else zipWith(-)(k1++k2)(v1++v2)
        ks<-newton options residual (d++d)
        let (k1,k2)=splitAt n ks
        z<-checked(add y(scale h(zipWith(\a b->3*a/4+b/4) k1 k2)))
        Right(z,replicate n 0)
    | otherwise=do
        let (cs,rows,weights,low)=tableau method
        ks<-stages f t h y cs rows
        high<-combine h y weights ks
        if method==DOP853 then do
            lastStage<-evaluate f(t+h)high
            let allStages=ks++[lastStage]
                errorPart coefficients=foldl add(replicate(length y)0)[scale w k|(w,k)<-zip coefficients allStages]
                e5=errorPart dop853E5; e3=errorPart dop853E3
                correction a b=let m=max(abs a)(0.1*abs b); denominator=if m==0 then 1 else sqrt((a/m)^ (2::Int)+(0.1*b/m)^ (2::Int))
                               in if m==0 then 0 else h*a*(abs a/m)/denominator
            err<-checked(zipWith correction e5 e3)
            Right(high,err)
        else case low of
            Just lowWeights->do lower<-combine h y lowWeights ks; err<-checked(zipWith(-)high lower); Right(high,err)
            Nothing->do
                halfKs<-stages f t(h/2)y cs rows; middle<-combine(h/2)y weights halfKs
                nextKs<-stages f(t+h/2)(h/2)middle cs rows; refined<-combine(h/2)middle weights nextKs
                let denominator=2**fromIntegral(methodOrder method-1)-1
                err<-checked(map(/denominator)(zipWith(-)refined high))
                Right(refined,err)

tableau :: Method -> ([Double],[[Double]],[Double],Maybe [Double])
tableau method=case method of
    Euler->([0],[[]],[1],Nothing)
    Heun->([0,1],[[],[1]],[1/2,1/2],Nothing)
    Midpoint->midpoint
    RK2->midpoint
    AdamsBashforth->rk4
    PredictorCorrector->rk4
    RK4->rk4
    RK23->([0,1/2,3/4,1],[[],[1/2],[0,3/4],[2/9,1/3,4/9]],[2/9,1/3,4/9,0],Just[7/24,1/4,1/3,1/8])
    RK45->([0,1/5,3/10,3/5,1,7/8],[[],[1/5],[3/40,9/40],[3/10,-9/10,6/5],[-11/54,5/2,-70/27,35/27],[1631/55296,175/512,575/13824,44275/110592,253/4096]],[37/378,0,250/621,125/594,0,512/1771],Just[2825/27648,0,18575/48384,13525/55296,277/14336,1/4])
    DormandPrince->([0,1/5,3/10,4/5,8/9,1,1],[[],[1/5],[3/40,9/40],[44/45,-56/15,32/9],[19372/6561,-25360/2187,64448/6561,-212/729],[9017/3168,-355/33,46732/5247,49/176,-5103/18656],[35/384,0,500/1113,125/192,-2187/6784,11/84]],[35/384,0,500/1113,125/192,-2187/6784,11/84,0],Just[5179/57600,0,7571/16695,393/640,-92097/339200,187/2100,1/40])
    DOP853->(dop853C,dop853A,dop853B,Nothing)
    _->rk4
    where midpoint=([0,1/2],[[],[1/2]],[0,1],Nothing)
          rk4=([0,1/2,1/2,1],[[],[1/2],[0,1/2],[0,0,1]],[1/6,1/3,1/3,1/6],Nothing)

fixedStep :: Method -> ODEOptions -> ODE -> Double -> Double -> [Double] -> Either MathError [Double]
fixedStep method options f t h y
    | method `elem` [Euler,Heun,Midpoint,RK2,RK4,AdamsBashforth,PredictorCorrector] =
        let (cs,rows,weights,_)=tableau method in stages f t h y cs rows >>= combine h y weights
    | otherwise = fst <$> oneStep method options f t h y

implicitStep :: ODEOptions -> ODE -> Double -> Double -> [Double] -> Maybe [Double] -> Bool -> Either MathError [Double]
implicitStep options f t h y old trapezoid=do
    d<-evaluate f t y
    predicted<-checked(add y(scale h d))
    let residual z=let dz=f(t+h)z in if length dz/=length y then replicate(length y)(0/0) else case old of
            Just previous->zipWith3(\a b c->a-4*b/3+c/3) z y previous `add` scale(-2*h/3) dz
            Nothing->if trapezoid then zipWith(-) z y `add` scale(-h/2)(add d dz) else zipWith(-) z y `add` scale(-h) dz
    newton options residual predicted

newton :: ODEOptions -> ([Double]->[Double]) -> [Double] -> Either MathError [Double]
newton options residual initial=checked initial >> go 0 initial
    where
        go iteration x=do
            let r=residual x
            require(length r==length x) "Newton residual dimension mismatch"
            _<-checked r
            if converged options x r then Right x
            else if iteration>=newtonIterations options then Left(NonConvergence "implicit Newton" iteration)
            else do
                matrix<-jacobian (sqrt(2.220446049250313e-16)*maximum(1:map abs x)) residual x
                delta<-solve matrix(map negate r)
                next<-checked(add x delta)
                if next==x then Left(NonConvergence "Newton floating-point resolution" iteration) else go(iteration+1)next

-- Compare componentwise after scaling, avoiding overflowing vector norms.
converged :: ODEOptions -> [Double] -> [Double] -> Bool
converged options x residual=and(zipWith acceptable x residual)
    where acceptable value r=let magnitude=max(odeAbsoluteTolerance options)(abs value)
                             in abs r/magnitude<=odeAbsoluteTolerance options/magnitude+odeRelativeTolerance options*(abs value/magnitude)

-- | Cubic Hermite interpolation inside the trajectory's closed time range.
-- Extrapolation, malformed public trajectories and repeated sample times fail.
interpolateTrajectory :: Trajectory -> Double -> Either MathError [Double]
interpolateTrajectory trajectory t=do
    let ts=trajectoryTimes trajectory; ys=trajectoryStates trajectory; ds=trajectoryDerivatives trajectory
        n=case ys of []->0; first:_->length first
        increasing=and(zipWith(<)ts(drop 1 ts)); decreasing=and(zipWith(>)ts(drop 1 ts))
    require (not(null ts)&&length ts==length ys&&length ts==length ds
        &&all(\v->length v==n&&all finite v)(ys++ds)&&all finite ts&&finite t
        &&(increasing||decreasing)) "malformed dense trajectory"
    require (t>=min(ts!!0)(last ts)&&t<=max(ts!!0)(last ts)) "dense-output time is outside trajectory"
    if t==last ts then Right(last ys) else if length ts==1 then Right(ys!!0) else do
        let intervals=zip4 ts(drop 1 ts)(zip ys ds)(zip(drop 1 ys)(drop 1 ds))
            selected=[(a,b,y0,d0,y1,d1)|(a,b,(y0,d0),(y1,d1))<-intervals,t>=min a b&&t<=max a b]
        case selected of
            []->Left(InvalidArgument "dense output has no containing interval")
            (a,b,y0,d0,y1,d1):_->do
                let h=b-a; s=(t-a)/h
                    w0=2*s^ (3::Int)-3*s^ (2::Int)+1; v0=s^ (3::Int)-2*s^ (2::Int)+s
                    w1= -2*s^ (3::Int)+3*s^ (2::Int); v1=s^ (3::Int)-s^ (2::Int)
                checked(foldl add(replicate n 0)[scale w0 y0,scale(h*v0)d0,scale w1 y1,scale(h*v1)d1])

zip4 :: [a]->[b]->[c]->[d]->[(a,b,c,d)]
zip4 (a:as)(b:bs)(c:cs)(d:ds)=(a,b,c,d):zip4 as bs cs ds
zip4 _ _ _ _=[]

-- | Event direction in increasing physical time, even for backward integration.
data EventDirection = AnyDirection | Rising | Falling deriving (Eq, Show)
-- | A located event time and its dense-interpolated state.
data Event = Event { eventTime :: Double, eventState :: [Double] } deriving (Eq, Show)
-- | Locate bracketed sign-changing events by dense-output bisection. Tangential
-- roots and multiple roots inside one sample interval are not guaranteed.
locateEvents :: EventDirection -> Double -> (Double->[Double]->Double) -> Trajectory -> Either MathError [Event]
locateEvents direction tolerance function trajectory=do
    require (finite tolerance&&tolerance>0) "event time tolerance must be positive"
    let ts=trajectoryTimes trajectory
    require(not(null ts)) "empty event trajectory"
    _<-interpolateTrajectory trajectory (ts!!0)
    pairs<-traverse (\t->do y<-interpolateTrajectory trajectory t; value<-scalar(function t y); Right(t,value)) ts
    events<-traverse locate(zip pairs(drop 1 pairs))
    Right(deduplicate(concat events))
    where
        scalar x=if finite x then Right x else Left NonFiniteResult
        accepts a b=case direction of AnyDirection->True; Rising->b>a; Falling->b<a
        locate ((a,fa),(b,fb))=do
            let (left,right,fl,fr)=if a<b then(a,b,fa,fb)else(b,a,fb,fa)
            if not(accepts fl fr)||(fl>0&&fr>0)||(fl<0&&fr<0) then Right []
            else if fl==0 then do y<-interpolateTrajectory trajectory left; Right[Event left y]
            else if fr==0 then do y<-interpolateTrajectory trajectory right; Right[Event right y]
            else do root<-bisect (0::Int) left right fl; y<-interpolateTrajectory trajectory root; Right[Event root y]
        bisect count left right fl
            | count>=100=Left(NonConvergence "event bisection" count)
            | right-left<=tolerance=Right(left+(right-left)/2)
            | otherwise=do
                let middle=left+(right-left)/2
                y<-interpolateTrajectory trajectory middle
                fm<-scalar(function middle y)
                if fm==0 then Right middle else if signum fm==signum fl then bisect(count+1)middle right fm else bisect(count+1)left middle fl
        deduplicate []=[]
        deduplicate (event:events)=event:deduplicate(dropWhile(\next->abs(eventTime next-eventTime event)<=tolerance)events)

-- | Shooting boundary-value solver: all initial-state components are unknown.
-- The boundary callback takes initial/final states and returns n residuals.
-- Returns the trajectory matching a locally converged shooting root; convergence
-- is local and depends on the supplied initial guess.
solveBoundary :: Method -> ODEOptions -> Int -> ODE -> ([Double]->[Double]->[Double]) -> Double -> Double -> [Double] -> Either MathError Trajectory
solveBoundary method options panels f boundary start end guess=do
    validateOptions options
    let residual initial=case solveIVP method options panels f start end initial of
            Left _->replicate(length initial)(0/0)
            Right trajectory->boundary initial(last(trajectoryStates trajectory))
    initial<-newton options residual guess
    solveIVP method options panels f start end initial

-- | Index-one implicit DAE driver F(t,y,y')=0 with backward differences.
-- Initial y and y' must be consistent to the configured tolerance. Each
-- subsequent state is obtained by a full residual Newton solve.
solveDAE :: ODEOptions -> Int -> (Double->[Double]->[Double]->[Double]) -> Double -> Double -> [Double] -> [Double] -> Either MathError Trajectory
solveDAE options panels residual start end initial initialDerivative=do
    validateOptions options
    require (panels>0&&panels<=maximumSteps options&&finite start&&finite end&&length initial==length initialDerivative&&all finite(initial++initialDerivative)) "invalid DAE input"
    let r0=residual start initial initialDerivative
    require(length r0==length initial&&all finite r0) "invalid initial DAE residual"
    require(converged options initial r0) "inconsistent initial DAE state/derivative"
    if start==end then Right(Trajectory[start][initial][initialDerivative]) else do
        let h=(end-start)/fromIntegral panels
            go i t y d times states derivatives
                | i==panels=Right(Trajectory(reverse times)(reverse states)(reverse derivatives))
                | otherwise=do
                    let nextTime=if i+1==panels then end else start+fromIntegral(i+1)*h; dt=nextTime-t
                    require(dt/=0) "DAE step rounded away"
                    let equation z=residual nextTime z(map(/dt)(zipWith(-)z y))
                    next<-newton options equation(add y(scale dt d))
                    dn<-checked(map(/dt)(zipWith(-)next y))
                    go(i+1)nextTime next dn(nextTime:times)(next:states)(dn:derivatives)
        go 0 start initial initialDerivative[start][initial][initialDerivative]

-- | Separable Hamiltonian methods for q'=velocity(p), p'=force(q).
data HamiltonianMethod = SymplecticEuler | Verlet | Leapfrog deriving(Eq,Show)
-- | Fixed-step symplectic integration; output states concatenate q then p.
-- Verlet is kick-drift-kick; Leapfrog is drift-kick-drift with integer-time
-- output momenta. These equivalent second-order splittings have distinct order.
solveHamiltonian :: HamiltonianMethod -> Int -> ([Double]->[Double]) -> ([Double]->[Double]) -> Double -> Double -> [Double] -> [Double] -> Either MathError Trajectory
solveHamiltonian method panels velocity force start end q0 p0=do
    require(panels>0&&length q0==length p0&&all finite(q0++p0)&&finite start&&finite end) "invalid Hamiltonian initial state or grid"
    let n=length q0
        evaluateVector f x=let y=f x in if length y/=n then Left(InvalidArgument "Hamiltonian callback dimension mismatch") else checked y
        deriv q p=do v<-evaluateVector velocity p; g<-evaluateVector force q; Right(v++g)
        step h q p=case method of
            SymplecticEuler->do g<-evaluateVector force q; p1<-checked(add p(scale h g)); v<-evaluateVector velocity p1; q1<-checked(add q(scale h v)); Right(q1,p1)
            Verlet->do g<-evaluateVector force q; pm<-checked(add p(scale(h/2)g)); v<-evaluateVector velocity pm; q1<-checked(add q(scale h v)); g1<-evaluateVector force q1; p1<-checked(add pm(scale(h/2)g1)); Right(q1,p1)
            Leapfrog->do v<-evaluateVector velocity p; qm<-checked(add q(scale(h/2)v)); g<-evaluateVector force qm; p1<-checked(add p(scale h g)); v1<-evaluateVector velocity p1; q1<-checked(add qm(scale(h/2)v1)); Right(q1,p1)
        go i t q p ts ys ds
            | i==panels=Right(Trajectory(reverse ts)(reverse ys)(reverse ds))
            | otherwise=do
                let nextTime=if i+1==panels then end else start+(end-start)*fromIntegral(i+1)/fromIntegral panels
                require(nextTime/=t) "Hamiltonian step rounded away"
                (q1,p1)<-step(nextTime-t)q p
                d1<-deriv q1 p1
                go(i+1)nextTime q1 p1(nextTime:ts)((q1++p1):ys)(d1:ds)
    d0<-deriv q0 p0
    if start==end then Right(Trajectory[start][q0++p0][d0]) else go 0 start q0 p0[start][q0++p0][d0]

-- | Fourth-order explicit Runge-Kutta-Nystrom method for q''=a(t,q), with
-- acceleration independent of velocity. State output concatenates q and q'.
solveNystrom :: Int -> (Double->[Double]->[Double]) -> Double -> Double -> [Double] -> [Double] -> Either MathError Trajectory
solveNystrom panels acceleration start end q0 v0=do
    require(panels>0&&finite start&&finite end&&length q0==length v0&&all finite(q0++v0)) "invalid Nystrom initial state or grid"
    let n=length q0
        acc t q=let a=acceleration t q in if length a/=n then Left(InvalidArgument "Nystrom callback dimension mismatch") else checked a
        go i t q v ts ys ds
            | i==panels=Right(Trajectory(reverse ts)(reverse ys)(reverse ds))
            | otherwise=do
                let nextTime=if i+1==panels then end else start+(end-start)*fromIntegral(i+1)/fromIntegral panels; h=nextTime-t
                require(h/=0) "Nystrom step rounded away"
                k1<-acc t q
                qm<-checked(foldl add q[scale(h/2)v,scale(h*h/8)k1])
                k2<-acc(t+h/2)qm
                qe<-checked(foldl add q[scale h v,scale(h*h/2)k2])
                k3<-acc nextTime qe
                q1<-checked(foldl add q[scale h v,scale(h*h/6)(add k1(scale 2 k2))])
                v1<-checked(add v(scale(h/6)(foldl add k1[scale 4 k2,k3])))
                a1<-acc nextTime q1
                go(i+1)nextTime q1 v1(nextTime:ts)((q1++v1):ys)((v1++a1):ds)
    a0<-acc start q0
    if start==end then Right(Trajectory[start][q0++v0][v0++a0]) else go 0 start q0 v0[start][q0++v0][v0++a0]

-- | Terminal-state parameter sensitivities by centered perturbation of the
-- complete IVP solve. Parameters use the same explicit finite-difference step.
sensitivities :: Method -> ODEOptions -> Int -> Double -> ([Double]->ODE) -> [Double] -> Double -> Double -> [Double] -> Either MathError (Matrix Double)
sensitivities method options panels h family parameters start end initial=do
    require(finite h&&h>0&&all finite parameters) "invalid sensitivity step or parameters"
    let terminal p=case solveIVP method options panels(family p)start end initial of
            Left _->replicate(length initial)(0/0)
            Right trajectory->last(trajectoryStates trajectory)
    matrix<-jacobian h terminal parameters
    Right(matrix)

-- | Find an autonomous equilibrium by a locally convergent Newton solve.
equilibrium :: ODEOptions -> ([Double]->[Double]) -> [Double] -> Either MathError [Double]
equilibrium options field guess=validateOptions options >> newton options field guess
-- | Compute autonomous phase-space trajectories for independently supplied starts.
phaseTrajectories :: Method -> ODEOptions -> Int -> ([Double]->[Double]) -> Double -> Double -> [[Double]] -> Either MathError [Trajectory]
phaseTrajectories method options panels field start end=traverse(solveIVP method options panels(\_ ->field)start end)

-- | Full Lyapunov spectrum by the Benettin tangent-space method: integrate
-- variational equations with RK4, then modified Gram-Schmidt at each sample.
-- Finite-difference Jacobians are used; results are finite-time estimates.
lyapunovExponents :: ODEOptions -> Int -> Double -> ODE -> Double -> Double -> [Double] -> Either MathError [Double]
lyapunovExponents options panels differenceStep f start end initial=do
    validateOptions options
    require(panels>0&&panels<=maximumSteps options&&finite differenceStep&&differenceStep>0&&finite start&&finite end&&end>start&&all finite initial) "invalid Lyapunov arguments"
    let n=length initial
        unit=[if i==j then 1 else 0|i<-[0..n-1],j<-[0..n-1]]
        augmented t state=let(y,v)=splitAt n state in case jacobian differenceStep(f t)y of
            Left _->replicate(n+n*n)(0/0)
            Right j->let values=toList j; dy=f t y
                     in if length dy/=n then replicate(n+n*n)(0/0) else dy++[sum[values!!(i*n+k)*v!!(k*n+c)|k<-[0..n-1]]|i<-[0..n-1],c<-[0..n-1]]
        orthogonalize columns=foldM orth ([],[]) columns
        orth(known,logs) column=do
            let remaining=foldl(\v q -> zipWith(-)v(scale(sum(zipWith(*)q v))q)) column known
                size=norm remaining
            require(finite size&&size>0) "Lyapunov tangent basis lost rank"
            Right(known++[scale(1/size)remaining],logs++[log size])
        go i y basis sums
            | i==panels=checked(map(/(end-start))sums)
            | otherwise=do
                let t=start+(end-start)*fromIntegral i/fromIntegral panels; h=(end-start)/fromIntegral panels
                next<-fixedStep RK4 options augmented t h(y++basis)
                let(y1,v1)=splitAt n next; columns=[[v1!!(r*n+c)|r<-[0..n-1]]|c<-[0..n-1]]
                (orthonormal,logs)<-orthogonalize columns
                go(i+1)y1(concat(transpose orthonormal))(add sums logs)
    if n==0 then Right[] else go 0 initial unit(replicate n 0)
