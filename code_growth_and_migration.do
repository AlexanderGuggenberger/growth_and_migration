

* empirical project for Macroeconometrics, SS 2019

clear
graph drop _all

cd "\\fs.univie.ac.at\homedirs\alexanderg15\Documents\macroeconometrics\project"

use macroeconometrics_project_guggenberger

tsset year

rename gdpgrowth dy

rename netmigrationrate m
* rename netmigration m


* SEPERATE ANALYSIS-------------------------------------------------------------

*GDP ---------------------------------------------------------------------------

* plots

tsline dy, name(gdpgrowth)
save dy, replace

ac dy, name(acdy)
pac dy, name(pacdy)

* Could be some ARMA process according to the graphs 

* model selection

* looks like an AR(3) or so, try all nine combinations of ARMA(p,q) for p=<3, q=<3 and compare BIC

matrix AICdy = (.,.,.,.\.,.,.,.\.,.,.,.)
matrix BICdy = (.,.,.,.\.,.,.,.\.,.,.,.)

local p=1

while `p'<=3{

local q=0

while `q'<=3{

quiet arima dy, arima(`p',0,`q') technique(dfp)
quiet estat ic
quiet matrix list r(S)
quiet matrix S=r(S)
quiet scalar aic=S[1,5]
quiet matrix AICdy[`p',`q'+1] = aic
quiet scalar bic=S[1,6]
quiet matrix BICdy[`p',`q'+1] = bic

local q=`q'+1

}

local p=`p'+1
}

matrix rownames AICdy = 1 2 3
matrix colnames AICdy = 0 1 2 3
matrix rownames BICdy = 1 2 3
matrix colnames BICdy = 0 1 2 3

matrix list AICdy
matrix list BICdy

*--> both criteria suggest it's an ARMA(1,1) process, which is plausible

arima dy, arima(1,0,1)

* unit-root-testing

dfuller dy, lags(1) trend

*--> no unit root --> stable process


*netmigration ------------------------------------------------------------------

* plots

tsline m, name(netmigration)
save m, replace

ac m, name(acm)
pac m, name(pacm)

* As the PAC falls from highly significant to insignificant after the first lag, this series has no MA elements


* model selection

matrix AICm = (.\.\.)
matrix BICm = (.\.\.)

local p=1

while `p'<=3{

local q=0

while `q'<=0{

quiet arima m, arima(`p',0,`q') technique(dfp)
quiet estat ic
quiet matrix list r(S)
quiet matrix S=r(S)
quiet scalar aic=S[1,5]
quiet matrix AICm[`p',`q'+1] = aic
quiet scalar bic=S[1,6]
quiet matrix BICm[`p',`q'+1] = bic

local q=`q'+1

}

local p=`p'+1
}

matrix rownames AICm = 1 2 3
matrix rownames BICm = 1 2 3


matrix list AICm
matrix list BICm

* --> Seems to be an AR(1) or AR(2) process --> furter testing applying the ...
* Portmanteau test

quietly arima m, arima(1,0,0) technique(dfp)
predict res1, res

quietly arima m, arima(2,0,0) technique(dfp)
predict res2, res

wntestq res1
wntestq res2

* I see that in both cases residuals are not significantly different from white noise, although the AR(2) specification leaves even a bit less structure in the residuals, as expected.
* However, as I have rather few observations, and the coefficient for the first lag is not biased fundamentally by including the second one, I will use the AR(1) model.

arima m, arima(1,0,0)

* unit-root-testing

dfuller m, lags(1) trend

*--> no unit root --> stable process


* JOINT ANALYSIS ---------------------------------------------------------------

* first of all, detrend the data, which avoids spurious regression results, yielding dyc (cyclical component of gdp growth) and mc -"-"-"-
* (because the df test said the data is stationary, but only when allowing for a trend)

tsfilter hp dyc=dy, smooth(100)
tsfilter hp mc=m, smooth(100)

tsline dyc, name(dyc)
tsline mc, name(mc)

varsoc mc dyc
xcorr mc dyc

eststo clear
eststo: quietly var mc dyc, lags(1)
eststo: quietly var mc dyc, lags(1/2)
eststo: quietly var mc dyc, lags(1/4)
esttab using resgressiontable.tex, compress se replace

* does not vary too much when increasing lag order --> use order 1:

var mc dyc, lags(1)

varstable, graph 

var m dy, lags(1)

varstable, graph 

varlmar, mlag(1)

*--> no significant autocorrelation in the errors

vargranger

*--> I can't reject that there is no granger causality

* impulse response function

irf set irfdym
irf create irfdym, replace

irf graph oirf


* trying a autoregressive distributed lags model

reg mc l.mc dyc l.dyc, robust
























