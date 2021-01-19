---
title: "COMPAS Recidivism Algorithm Case Study"
author: "Octavio Mesner"
date: "9/21/2020"
output: 
  html_document:
    keep_md: true
header-includes: 
  - \usepackage{tikz}
  - \usepackage{pgfplots}
---


## About me

- Worked as a biostatistician for 5 years in HIV/STI research
- Did joint PhD in Engineering and Public Policy and in Statistics and Data Science
- Thesis topic on non-parametric causal discovery
- First time teaching this class, I would appreciate constructive feedback
- Course goal: prepare students in this class for master-level consulting

## Consulting Skills Focus

- In real life consulting, the client will frequently understand the data and surrounding research better than the statistician.
- Question: have many have done statistical consulting in the past?
- Analysis should center around a well-defined research question that drive the analysis and the data should be able to provide insight on the question of interest.
- Bias and data analysis: We all have bias.  This can influence data analysis.  A data analyst, we should do our best to objectively present the data.  When necessary to make assumptions, state them explicitly.  
- Researchers frequently want "positive results."  Usually this means significant p-values.  Variable selection is a simple way to change p-values, p-hacking.  It's common to need to change variables in a model be it should be done a principled way.
- Analysis should be transparent and reproducible.  [R Markdown](https://rmarkdown.rstudio.com) and [Jupyter Notebook](https://jupyter.org) make this very easy.  This work is done in R Markdown.  At the end of this case study, you will need to include your reproducible analysis along with the memo.

## Case Study Background

- US has more inmates, proportional to population size, than any other country.   While Black Americans make up 13% of the total US population, they account for 40% of incarcerated population in the US.
![incarceration world map](./Prisoners_world_map_png2.png)
Image from [Wikipedia](https://en.wikipedia.org/wiki/Incarceration_in_the_United_States#/media/File:Prisoners_world_map_png2.png)
- In the US justice system, machine learning algorithms are sometimes used to assess a criminal defendant's risk of recidivism (arrest due to committing a future crime) are being used.
- Correctional Offenders Management Profiling for Alternative Sanctions (COMPAS) is the most widespread of these algorithms.
- Its goal according to COMPAS creators: assess "not just risk but also nearly two dozen so-called “criminogenic needs” that relate to the major theories of criminality, including “criminal personality,” “social isolation,” “substance abuse” and “residence/stability.” Defendants are ranked low, medium or high risk in each category."
- In 2014, then U.S. Attorney General Eric Holder warned that the risk scores might be injecting bias into the courts. He called for the U.S. Sentencing Commission to study their use. “Although these measures were crafted with the best of intentions, I am concerned that they inadvertently undermine our efforts to ensure individualized and equal justice,” he said, adding, “they may exacerbate unwarranted and unjust disparities that are already far too common in our criminal justice system and in our society.”
- The [questionnaire](https://www.documentcloud.org/documents/2702103-Sample-Risk-Assessment-COMPAS-CORE.html) for determining COMPAS does not directly ask for race, but some people question inherent racial bias in the algorithm.
- The COMPAS algorithm is proprietary and not available.
- More information in a [2016 ProPublica article](https://www.propublica.org/article/machine-bias-risk-assessments-in-criminal-sentencing).


## Data

- ProPublica requested two years of COMPAS scores from Broward County Sheriff's Office in Florida
- Discarded all but pre-trial COMPAS score assessments
- ProPublica matched COMPAS scores with criminal records from Broward County Clerk's Office website
- COMPAS score screening date and (original) arrest date frequently differed.  If they are too far apart, that may indicate an error.  The `days_b_screening_arrest` variable gives this difference in days.
- `is_recid` is rearrest at any time.  `two_year_recid` is rearrest within two years.  Here, `-1` indicates a COMPAS record could not be found and should probably be discarded
- COMPAS generates a general score, `decile_score`, (1, 2,...,10) where 1 indicates a low risk and 10 indicates a high risk of recidivism.  There is also a violence score as well, `v_decile_score`.


```r
dat<-read.csv("./compas-scores.csv")
dim(dat)
```

```
## [1] 11757    47
```

```r
names(dat)
```

```
##  [1] "id"                      "name"                   
##  [3] "first"                   "last"                   
##  [5] "compas_screening_date"   "sex"                    
##  [7] "dob"                     "age"                    
##  [9] "age_cat"                 "race"                   
## [11] "juv_fel_count"           "decile_score"           
## [13] "juv_misd_count"          "juv_other_count"        
## [15] "priors_count"            "days_b_screening_arrest"
## [17] "c_jail_in"               "c_jail_out"             
## [19] "c_case_number"           "c_offense_date"         
## [21] "c_arrest_date"           "c_days_from_compas"     
## [23] "c_charge_degree"         "c_charge_desc"          
## [25] "is_recid"                "num_r_cases"            
## [27] "r_case_number"           "r_charge_degree"        
## [29] "r_days_from_arrest"      "r_offense_date"         
## [31] "r_charge_desc"           "r_jail_in"              
## [33] "r_jail_out"              "is_violent_recid"       
## [35] "num_vr_cases"            "vr_case_number"         
## [37] "vr_charge_degree"        "vr_offense_date"        
## [39] "vr_charge_desc"          "v_type_of_assessment"   
## [41] "v_decile_score"          "v_score_text"           
## [43] "v_screening_date"        "type_of_assessment"     
## [45] "decile_score.1"          "score_text"             
## [47] "screening_date"
```

```r
#head(dat)
#summary(dat)
```


```r
table(dat$sex)
```

```
## 
## Female   Male 
##   2421   9336
```

```r
table(dat$sex)/sum(!is.na(dat$sex))*100
```

```
## 
##   Female     Male 
## 20.59199 79.40801
```


```r
library(ggplot2)
ggplot(dat, aes(x=age, color=sex, fill=sex)) +
  geom_histogram(position="dodge")
```

```
## `stat_bin()` using `bins = 30`. Pick better value with `binwidth`.
```

![](compasRecidAlg_files/figure-html/age-1.png)<!-- -->


```r
ggplot(dat, aes(race)) +
  geom_bar(fill='blue')
```

![](compasRecidAlg_files/figure-html/race-1.png)<!-- -->

```r
ggplot(dat, aes(x=race, fill=sex)) +
  geom_bar(position='dodge')
```

![](compasRecidAlg_files/figure-html/race-2.png)<!-- -->


```r
ggplot(dat, aes(decile_score)) +
  geom_histogram()
```

```
## `stat_bin()` using `bins = 30`. Pick better value with `binwidth`.
```

![](compasRecidAlg_files/figure-html/compas-1.png)<!-- -->

```r
table(!is.na(dat$decile_score))
```

```
## 
##  TRUE 
## 11757
```

General recommendations:

- Look at the raw data and different plots of the data before doing any modeling.
- Look for missing data and for values that might not make sense.
- Make sure you understand what observations (rows) are included in the data and which of those observations serve your data analysis goals
- Try to understand what the variables (columns) represent and which ones will serve your data analysis goals

## Quantifying racial bias

- Before doing any analysis, let's look at recidivism, COMPAS, and race


```r
df <- dat[dat$is_recid != -1,]
sum(is.na(df$race))
```

```
## [1] 0
```

```r
sum(is.na(df$is_recid))
```

```
## [1] 0
```

```r
table(df$race, df$is_recid)[,2]/t(table(df$race))*100
```

```
##       
##        African-American    Asian Caucasian Hispanic Native American    Other
##   [1,]         39.53827 20.75472  28.52279 25.86720        36.11111 24.79871
```
Above is the recidivism rate by race

- COMPAS also gave Black Americans greater scores on average:

```r
tapply(df$decile_score, df$race, mean)
```

```
## African-American            Asian        Caucasian         Hispanic 
##         5.326850         2.735849         3.647459         3.313181 
##  Native American            Other 
##         4.805556         2.813205
```
Is this the best way to present this information?

## How to model algorithmic bias?
- What does bias mean here?
- Would COMPAS give someone a greater score solely due to being Black, without changing anything else?
- Remember COMPAS doesn't ask for race directly.
- How could we quantify bias in this case?  Are race and COMPAS still associated after taking recidivism into account?
- It is tempting to use `decile_score ~ is_recid + race` to quantify the association between COMPAS and race while controlling for recidivism.

## Collider Bias

[Causal comic](https://xkcd.com/552/)

**Scenario 1:**
<!--html_preserve--><div id="htmlwidget-7d3505b6fe7badcc21e1" style="width:40%;height:480px;" class="grViz html-widget"></div>
<script type="application/json" data-for="htmlwidget-7d3505b6fe7badcc21e1">{"x":{"diagram":"digraph flowchart {A -> B -> C;}","config":{"engine":"dot","options":null}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->
What would a regression model of `C ~ A + B` yield?


```r
set.seed(1234)
size <- 1000
A <- 6*rnorm(size)+50
B <- -2*A - 25 + rnorm(size)
C <- 5*B + 3 +rnorm(size)
summary(lm(C~A+B))
```

```
## 
## Call:
## lm(formula = C ~ A + B)
## 
## Residuals:
##      Min       1Q   Median       3Q      Max 
## -3.13161 -0.71957  0.03478  0.70215  3.05316 
## 
## Coefficients:
##             Estimate Std. Error t value Pr(>|t|)    
## (Intercept)  1.96001    0.87456   2.241   0.0252 *  
## A           -0.07084    0.06532  -1.085   0.2784    
## B            4.96310    0.03270 151.761   <2e-16 ***
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
## Residual standard error: 1.013 on 997 degrees of freedom
## Multiple R-squared:  0.9997,	Adjusted R-squared:  0.9997 
## F-statistic: 1.739e+06 on 2 and 997 DF,  p-value: < 2.2e-16
```
What about this regression model: `C ~ A`?

```r
summary(lm(C~A))
```

```
## 
## Call:
## lm(formula = C ~ A)
## 
## Residuals:
##      Min       1Q   Median       3Q      Max 
## -15.9753  -3.4048  -0.0059   3.2714  16.5278 
## 
## Coefficients:
##               Estimate Std. Error t value Pr(>|t|)    
## (Intercept) -124.34246    1.31868  -94.29   <2e-16 ***
## A             -9.95096    0.02627 -378.80   <2e-16 ***
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
## Residual standard error: 4.969 on 998 degrees of freedom
## Multiple R-squared:  0.9931,	Adjusted R-squared:  0.9931 
## F-statistic: 1.435e+05 on 1 and 998 DF,  p-value: < 2.2e-16
```

Does this coefficient and intercept estimate make sense?
$C = 5B + 3 + \epsilon_B = 5(-2A - 25 + \epsilon_A) = -10A - 122 + 5\epsilon_A + \epsilon_B$

**Scenario 2:**
<!--html_preserve--><div id="htmlwidget-4ab6cac85bce3e63d4af" style="width:40%;height:480px;" class="grViz html-widget"></div>
<script type="application/json" data-for="htmlwidget-4ab6cac85bce3e63d4af">{"x":{"diagram":"digraph flowchart {A -> B; A -> C;}","config":{"engine":"dot","options":null}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->


```r
set.seed(1234)
size <- 1000
A <- 6*rnorm(size)+50
B <- -2*A - 25 + rnorm(size)
C <- 2*A +5 +rnorm(size)
summary(lm(C~A+B))
```

```
## 
## Call:
## lm(formula = C ~ A + B)
## 
## Residuals:
##      Min       1Q   Median       3Q      Max 
## -3.13161 -0.71957  0.03478  0.70215  3.05316 
## 
## Coefficients:
##             Estimate Std. Error t value Pr(>|t|)    
## (Intercept)  3.96001    0.87456   4.528 6.67e-06 ***
## A            1.92916    0.06532  29.533  < 2e-16 ***
## B           -0.03690    0.03270  -1.128    0.259    
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
## Residual standard error: 1.013 on 997 degrees of freedom
## Multiple R-squared:  0.9929,	Adjusted R-squared:  0.9929 
## F-statistic: 6.996e+04 on 2 and 997 DF,  p-value: < 2.2e-16
```
What about this regression model: `C ~ A`?  Try it!

**Scenario 3:**
<!--html_preserve--><div id="htmlwidget-4aad06d3811b05f2b761" style="width:40%;height:480px;" class="grViz html-widget"></div>
<script type="application/json" data-for="htmlwidget-4aad06d3811b05f2b761">{"x":{"diagram":"digraph flowchart {A -> C; B -> C;}","config":{"engine":"dot","options":null}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->


```r
set.seed(1234)
size <- 1000
A <- 6*rnorm(size)+50
B <- -2*rnorm(size) - 25 + rnorm(size)
C <- -4*A + 5*B + 3 +rnorm(size)
summary(lm(C~A+B))
```

```
## 
## Call:
## lm(formula = C ~ A + B)
## 
## Residuals:
##      Min       1Q   Median       3Q      Max 
## -3.03321 -0.68565  0.01655  0.66794  3.13811 
## 
## Coefficients:
##              Estimate Std. Error  t value Pr(>|t|)    
## (Intercept)  2.967859   0.430869    6.888    1e-11 ***
## A           -4.000487   0.005264 -759.946   <2e-16 ***
## B            4.998128   0.014068  355.283   <2e-16 ***
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
## Residual standard error: 0.9947 on 997 degrees of freedom
## Multiple R-squared:  0.9986,	Adjusted R-squared:  0.9986 
## F-statistic: 3.641e+05 on 2 and 997 DF,  p-value: < 2.2e-16
```

**Scenario 3 with `A` as the outcome:**

```r
summary(lm(A~B+C))
```

```
## 
## Call:
## lm(formula = A ~ B + C)
## 
## Residuals:
##      Min       1Q   Median       3Q      Max 
## -0.75638 -0.17022  0.00544  0.16841  0.80335 
## 
## Coefficients:
##               Estimate Std. Error  t value Pr(>|t|)    
## (Intercept)  0.8215779  0.1070244    7.677 3.89e-14 ***
## B            1.2470301  0.0039408  316.439  < 2e-16 ***
## C           -0.2495388  0.0003284 -759.946  < 2e-16 ***
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
## Residual standard error: 0.2484 on 997 degrees of freedom
## Multiple R-squared:  0.9983,	Adjusted R-squared:  0.9983 
## F-statistic: 2.893e+05 on 2 and 997 DF,  p-value: < 2.2e-16
```

```r
summary(lm(A~B))
```

```
## 
## Call:
## lm(formula = A ~ B)
## 
## Residuals:
##      Min       1Q   Median       3Q      Max 
## -19.9644  -3.8309  -0.0804   3.8547  19.3418 
## 
## Coefficients:
##             Estimate Std. Error t value Pr(>|t|)    
## (Intercept) 46.99023    2.12137  22.151   <2e-16 ***
## B           -0.11401    0.08452  -1.349    0.178    
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
## Residual standard error: 5.982 on 998 degrees of freedom
## Multiple R-squared:  0.00182,	Adjusted R-squared:  0.0008198 
## F-statistic:  1.82 on 1 and 998 DF,  p-value: 0.1777
```

- Even though `A` and `B` are independent, they are *conditionally dependent* if controlling for `C`.
- Why did this happen?  Does it make sense?
- Consider $A\sim \text{Bernoulli}(0.5), B\sim \text{Bernoulli}(0.5)$ (independent coin flips), and $C = A\cdot B$.  
- $A$ and $B$ are independent; that is, knowledge of $B$ give no information on the value of $A$. But, additional knowledge of $C$ does give information about the value of $A$.

**Scenario 4**
<!--html_preserve--><div id="htmlwidget-20a4dade433d6eade8f5" style="width:40%;height:480px;" class="grViz html-widget"></div>
<script type="application/json" data-for="htmlwidget-20a4dade433d6eade8f5">{"x":{"diagram":"digraph flowchart {A -> C; B -> C; A -> B}","config":{"engine":"dot","options":null}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->


```r
set.seed(1234)
size <- 1000
A <- 6*rnorm(size)+50
B <- A - 2*rnorm(size) - 25 + rnorm(size)
C <- -4*A + 5*B + 3 +rnorm(size)
summary(lm(C~A+B))
```

```
## 
## Call:
## lm(formula = C ~ A + B)
## 
## Residuals:
##      Min       1Q   Median       3Q      Max 
## -3.03321 -0.68565  0.01655  0.66794  3.13811 
## 
## Coefficients:
##             Estimate Std. Error  t value Pr(>|t|)    
## (Intercept)  2.96786    0.43087    6.888    1e-11 ***
## A           -3.99861    0.01481 -270.015   <2e-16 ***
## B            4.99813    0.01407  355.283   <2e-16 ***
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
## Residual standard error: 0.9947 on 997 degrees of freedom
## Multiple R-squared:  0.9937,	Adjusted R-squared:  0.9937 
## F-statistic: 7.84e+04 on 2 and 997 DF,  p-value: < 2.2e-16
```

```r
summary(lm(C~A))
```

```
## 
## Call:
## lm(formula = C ~ A)
## 
## Residuals:
##     Min      1Q  Median      3Q     Max 
## -31.978  -7.970  -0.193   7.748  38.531 
## 
## Coefficients:
##               Estimate Std. Error t value Pr(>|t|)    
## (Intercept) -118.00904    2.98084  -39.59   <2e-16 ***
## A              0.91973    0.05938   15.49   <2e-16 ***
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
## Residual standard error: 11.23 on 998 degrees of freedom
## Multiple R-squared:  0.1938,	Adjusted R-squared:  0.193 
## F-statistic: 239.9 on 1 and 998 DF,  p-value: < 2.2e-16
```

## COMPAS and possible collider bias

COMPAS uses [questionnaire](https://www.documentcloud.org/documents/2702103-Sample-Risk-Assessment-COMPAS-CORE.html) responses (Q in the diagram) to predict recidivism.  
<!--html_preserve--><div id="htmlwidget-60bae7d82545c6e16e82" style="width:40%;height:480px;" class="grViz html-widget"></div>
<script type="application/json" data-for="htmlwidget-60bae7d82545c6e16e82">{"x":{"diagram":"digraph flowchart {Race -> Q -> COMPAS; Q -> Recidivism; Race -> Recidivism}","config":{"engine":"dot","options":null}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

Because COMPAS is used in sentencing, it may actually impact recidivism as well.
<!--html_preserve--><div id="htmlwidget-b95159ff31130ca6e597" style="width:40%;height:480px;" class="grViz html-widget"></div>
<script type="application/json" data-for="htmlwidget-b95159ff31130ca6e597">{"x":{"diagram":"digraph flowchart {Race -> Q -> COMPAS; Q -> Recidivism; COMPAS -> Recidivism; Race -> Recidivism}","config":{"engine":"dot","options":null}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

One way to quantify racial bias in COMPAS would be to isolate the link between race and COMPAS that is not associated with recidivism.  But, it is not clear how to untangle this from potential collider bias.
<!--html_preserve--><div id="htmlwidget-bf84a974895a9dfd1dff" style="width:40%;height:480px;" class="grViz html-widget"></div>
<script type="application/json" data-for="htmlwidget-bf84a974895a9dfd1dff">{"x":{"diagram":"digraph flowchart {Race -> Q -> COMPAS; Q -> Recidivism; COMPAS -> Recidivism; Race -> Recidivism; Race-> COMPAS}","config":{"engine":"dot","options":null}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

If we used `decile_score ~ is_recid + race` as a model to quantify bias, it seems very likely that there will be collider bias.


```r
summary(lm(decile_score ~ is_recid + race, data=df))
```

```
## 
## Call:
## lm(formula = decile_score ~ is_recid + race, data = df)
## 
## Residuals:
##    Min     1Q Median     3Q    Max 
## -7.225 -2.224 -0.225  1.776  7.555 
## 
## Coefficients:
##                     Estimate Std. Error t value Pr(>|t|)    
## (Intercept)          4.73952    0.04127 114.848  < 2e-16 ***
## is_recid             1.48548    0.05345  27.794  < 2e-16 ***
## raceAsian           -2.31198    0.36300  -6.369 1.98e-10 ***
## raceCaucasian       -1.51576    0.05569 -27.217  < 2e-16 ***
## raceHispanic        -1.81059    0.09033 -20.043  < 2e-16 ***
## raceNative American -0.47038    0.43961  -1.070    0.285    
## raceOther           -2.29469    0.11157 -20.566  < 2e-16 ***
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
## Residual standard error: 2.629 on 11031 degrees of freedom
## Multiple R-squared:  0.1656,	Adjusted R-squared:  0.1652 
## F-statistic: 364.9 on 6 and 11031 DF,  p-value: < 2.2e-16
```

In the regression above, several race indicator variables are significant.  But, because collider bias is possible here, we *cannot* conclude that COMPAS is racially biased.

## Survival Analysis

- Survival analysis is a set of statistical methods for modeling the time until an event occurs, especially when follow up is not complete for each observation.
- Example: Testing a new terminal cancer treatment, participants are either given the standard or test treatment.  The goal is to prolong the patient's.  Each patient is followed until death from cancer.  During follow up some participants die from cancer but some drop out while others might die from something else.  Survival analysis allows us to use this data even though we do not have events for each participant.

**Set up**

Assume that $T$ is the time until an event randomly occurs.
For example, $T$ might be the duration from cancer treatment until remission or death.


Let $f(t)$ be a probability density function where $t$ is time, $T\sim f$ be a random variable, and let $F(t)=P(T<t)=\int_0^tf(x)dx$ be its cumulative distribution function.
Define the survival function as $S(t)=P(T>t)=1-F(t)$ and the hazard function as
\[
\lambda(t)=\lim_{h\rightarrow 0} \frac{P(t<T\leq t+h)}{P(T>t)}= \frac{f(t)}{S(t)} = -\frac{d\log S(t)}{dt}.
\]
Notice that $f(t)=\lambda(t)S(t)$.

The cumulative hazard function is defined as
\[
\Lambda(t)= \int_0^t\lambda(x)dx=-\int_0^td\log S(x)=-\log S(t).
\]
So,
\[
S(t)=\exp[-\Lambda(t)].
\]
Side note: If we model $\lambda(t)=\lambda$ (constant function), then $\Lambda(t)=\lambda t$. So, $f(t)=\lambda\exp(-\lambda t)$ is the exponential distribution.

**Censoring at Random**

With many of time-to-event studies, it is not always possible to wait for an event to occur for each participant before doing the analysis.  In a cancer study, for example, participants may drop out of the study before an event is observed or the study may close before each participant experiences an event.  This is call right censored data.
While in some cases, a participant does not contribute the entire time until the event occurs, intuitively, we should be able to make use of the time where the event did not occur.

![right censoring image from [here](http://reliawiki.org/index.php/Life_Data_Classification)](./Right_censoring.png)

- Let $f(t;\theta), \lambda(t;\theta)$, and $S(t;\theta)$ be the density, hazard, and survival functions with parameter $\theta$ for the time to the event of interest.
- We assume that censoring occurs at random (in independently from $f$), say it has cumulative distribution of $G(t;\phi)$ (with some parameter $\phi$) and density function, $g(t;\phi)$.
- Let $(t_1, \delta_1),\dots, (t_n,\delta_n)$ be a sample of size $n$ where $\delta_i$ indicates censoring and $t_i$ is the time to event or censor.  That is $t_i \sim f(t;\theta)$ when $\delta_i=1$ and $t_i \sim g(t;\phi)$ when $\delta_i=0$.
- The Likelihood is 
\[
\begin{align}
L(\theta,\phi) &= \prod_{i=1}^n [f(t_i;\theta)[1-G(t_i;\phi)]]^{\delta_i} [g(t_i;\phi)S(t_i;\theta)]^{1-\delta_i}\\
&=  \prod_{i=1}^n [f(t_i;\theta)]^{\delta_i}[S(t_i;\theta)]^{1-\delta_i} \prod_{i=1}^n [g(t_i;\phi)]^{1-\delta_1}[1-G(t_i;\phi)]^{\delta_i}\\
&= L(\theta) L(\phi) \propto L(\theta).
\end{align}
\]

- Unpacking this a bit, if we observe an event, its density is $f$ and censoring did not occur prior: $[f(t_i;\theta)[1-G(t_i;\phi)]]^{\delta_i}$.  
If we observe censoring, its density is $g$ and an event did not occur prior: $[g(t_i;\phi)S(t_i;\theta)]^{1-\delta_i}$.
But, we do not care about the censoring distribution, only the time to event distribution.

- Note that $L(\theta)=\prod_{i=1}^n [f(t_i;\theta)]^{\delta_i}[S(t_i;\theta)]^{1-\delta_i}= \prod_{i=1}^n \lambda(t_i)^{\delta_i} S(t_i)$ is what we actually care about here.

## Kaplan-Meier Estimator

- Consider estimating $S(t) = P(T>t)$ from the sample ordered by $t_i$, $(t_{1}, \delta_{1}), (t_{2}, \delta_{2}), \dots, (t_{n}, \delta_{n})$ and let $t_{(1)}, t_{(2)}, \dots, t_{(J)}$ be the ordered event times, where $\delta_i=1$.
- Because there are only $J$ points in time where events occur, we approximate $S(t)$ as a decreasing step function.
- $S(t_{(j)}) = P(T > t_{(j)}) = P(T > t_{(j)} | T > t_{(j-1)}) P(T > t_{(j-1)})$ because for $t > s, P(T>t) = P(T>t, T>s) = P(T>t|T>s)P(T>s)$.
- For $j = 1,\dots, J$, let $\pi_j = 1-P(T > t_{(j)} | T > t_{(j-1)})$ be the "instantaneous" probability of an event occurring at time $t_j$.
- Then 
\[
S(t_{(j)}) = (1-\pi_j)(1-\pi_{j-1}) \dots (1-\pi_2)(1-\pi_1).
\]
- Let $n_j = \#\{t_i \geq t_{(j)}\}$ be the number of participants who are still at risk (who haven't had an event or been censored) at time $t_{(j)}$.  Note that $n_j$ decreases as events occur or as they are censored.
- Let $d_j = \#\{t_i=t_{(j)}, \delta_i=1\}$ be the number of events that occur at time $t_{(j)}$.
- We can show that $\pi_j = \frac{d_j}{n_j}$ maximized the non-parametric likelihood.
- So, we can approximate the survival function as
\[
\hat S(t) = \prod_{j=1}^J \left( 1-\frac{d_j}{n_j}\right)^{I(t_{(j)}\leq t)}.
\]
- Using the delta-method, we can approxmiate the variance of the estimated survival function as 
\[
\hat V[\hat S(t)] = \hat S(t)^2 \sum_{j: t_{(j)}\leq t} \frac{d_j}{n_j(n_j-d_j)}
\]

This [video](https://www.youtube.com/watch?v=NDgn72ynHcM) clearly illustrates how to calculate the KM survival function.


```r
library(survival)
library(ggfortify)

dat <- read.csv(url('https://raw.githubusercontent.com/propublica/compas-analysis/master/cox-parsed.csv'))
names(dat)
```

```
##  [1] "id"                      "name"                   
##  [3] "first"                   "last"                   
##  [5] "compas_screening_date"   "sex"                    
##  [7] "dob"                     "age"                    
##  [9] "age_cat"                 "race"                   
## [11] "juv_fel_count"           "decile_score"           
## [13] "juv_misd_count"          "juv_other_count"        
## [15] "priors_count"            "days_b_screening_arrest"
## [17] "c_jail_in"               "c_jail_out"             
## [19] "c_case_number"           "c_offense_date"         
## [21] "c_arrest_date"           "c_days_from_compas"     
## [23] "c_charge_degree"         "c_charge_desc"          
## [25] "is_recid"                "r_case_number"          
## [27] "r_charge_degree"         "r_days_from_arrest"     
## [29] "r_offense_date"          "r_charge_desc"          
## [31] "r_jail_in"               "r_jail_out"             
## [33] "violent_recid"           "is_violent_recid"       
## [35] "vr_case_number"          "vr_charge_degree"       
## [37] "vr_offense_date"         "vr_charge_desc"         
## [39] "type_of_assessment"      "decile_score.1"         
## [41] "score_text"              "screening_date"         
## [43] "v_type_of_assessment"    "v_decile_score"         
## [45] "v_score_text"            "v_screening_date"       
## [47] "in_custody"              "out_custody"            
## [49] "priors_count.1"          "start"                  
## [51] "end"                     "event"
```

```r
dim(dat)
```

```
## [1] 13419    52
```

```r
dat2 <- dat[dat$end > dat$start,]
dim(dat2)
```

```
## [1] 13356    52
```

```r
dat3 <- dat2[!duplicated(dat2$id),]
dim(dat3)
```

```
## [1] 10325    52
```

```r
ph <- dat3[!is.na(dat3$decile_score),]
dim(ph)
```

```
## [1] 10325    52
```

```r
ph$t_atrisk <- ph$end - ph$start

survobj <- with(ph, Surv(t_atrisk, event))
fit0 <- survfit(survobj~1, data=ph)
summary(fit0)
```

```
## Call: survfit(formula = survobj ~ 1, data = ph)
## 
##  time n.risk n.event survival  std.err lower 95% CI upper 95% CI
##     1  10325      17    0.998 0.000399        0.998        0.999
##     2  10213      18    0.997 0.000575        0.995        0.998
##     3  10192      15    0.995 0.000687        0.994        0.996
##     4  10176      19    0.993 0.000808        0.992        0.995
##     5  10151      16    0.992 0.000896        0.990        0.993
##     6  10128      13    0.990 0.000962        0.989        0.992
##     7  10110      18    0.989 0.001046        0.987        0.991
##     8  10082      20    0.987 0.001132        0.984        0.989
##     9  10056      11    0.986 0.001177        0.983        0.988
##    10  10039      11    0.985 0.001220        0.982        0.987
##    11  10022       8    0.984 0.001250        0.981        0.986
##    12  10010      13    0.982 0.001298        0.980        0.985
##    13   9994      15    0.981 0.001351        0.978        0.984
##    14   9969      12    0.980 0.001391        0.977        0.983
##    15   9951      12    0.979 0.001431        0.976        0.981
##    16   9933      12    0.977 0.001469        0.975        0.980
##    17   9914       9    0.977 0.001497        0.974        0.980
##    18   9896      14    0.975 0.001540        0.972        0.978
##    19   9875      18    0.973 0.001593        0.970        0.977
##    20   9852      14    0.972 0.001633        0.969        0.975
##    21   9830      13    0.971 0.001670        0.967        0.974
##    22   9807      10    0.970 0.001697        0.966        0.973
##    23   9788       7    0.969 0.001716        0.966        0.972
##    24   9775      12    0.968 0.001748        0.964        0.971
##    25   9753      11    0.967 0.001777        0.963        0.970
##    26   9734       8    0.966 0.001797        0.962        0.970
##    27   9721       7    0.965 0.001815        0.962        0.969
##    28   9709      10    0.964 0.001840        0.961        0.968
##    29   9690      14    0.963 0.001875        0.959        0.967
##    30   9666      12    0.962 0.001904        0.958        0.965
##    31   9642      14    0.960 0.001937        0.957        0.964
##    32   9620      10    0.959 0.001961        0.955        0.963
##    33   9603      12    0.958 0.001989        0.954        0.962
##    34   9581      14    0.957 0.002021        0.953        0.961
##    35   9553      11    0.956 0.002046        0.952        0.960
##    36   9528       5    0.955 0.002057        0.951        0.959
##    37   9512      12    0.954 0.002083        0.950        0.958
##    38   9493       8    0.953 0.002101        0.949        0.957
##    39   9474      11    0.952 0.002125        0.948        0.956
##    40   9453       9    0.951 0.002144        0.947        0.955
##    41   9438       7    0.950 0.002159        0.946        0.955
##    42   9425      11    0.949 0.002182        0.945        0.954
##    43   9410       5    0.949 0.002193        0.944        0.953
##    44   9395      10    0.948 0.002214        0.943        0.952
##    45   9381       5    0.947 0.002224        0.943        0.952
##    46   9371      11    0.946 0.002246        0.942        0.951
##    47   9355      13    0.945 0.002273        0.940        0.949
##    48   9334       9    0.944 0.002291        0.939        0.948
##    49   9316      10    0.943 0.002311        0.938        0.947
##    50   9295      17    0.941 0.002344        0.937        0.946
##    51   9274       7    0.940 0.002357        0.936        0.945
##    52   9253       8    0.940 0.002373        0.935        0.944
##    53   9233      11    0.939 0.002394        0.934        0.943
##    54   9210      10    0.938 0.002413        0.933        0.942
##    55   9195      13    0.936 0.002437        0.931        0.941
##    56   9172       5    0.936 0.002447        0.931        0.940
##    57   9156       5    0.935 0.002456        0.930        0.940
##    58   9142       6    0.935 0.002467        0.930        0.939
##    59   9126       9    0.934 0.002484        0.929        0.939
##    60   9112       6    0.933 0.002495        0.928        0.938
##    61   9097      12    0.932 0.002517        0.927        0.937
##    62   9077       8    0.931 0.002531        0.926        0.936
##    63   9062       8    0.930 0.002546        0.925        0.935
##    64   9049       7    0.929 0.002558        0.924        0.934
##    65   9030       5    0.929 0.002567        0.924        0.934
##    66   9021      11    0.928 0.002586        0.923        0.933
##    67   9000       7    0.927 0.002599        0.922        0.932
##    68   8984       6    0.926 0.002609        0.921        0.932
##    69   8972       7    0.926 0.002622        0.921        0.931
##    70   8956       9    0.925 0.002637        0.920        0.930
##    71   8935       7    0.924 0.002649        0.919        0.929
##    72   8919       6    0.923 0.002660        0.918        0.929
##    73   8905       4    0.923 0.002667        0.918        0.928
##    74   8896       6    0.922 0.002677        0.917        0.928
##    75   8881       6    0.922 0.002687        0.917        0.927
##    76   8868      11    0.921 0.002706        0.915        0.926
##    77   8852       7    0.920 0.002718        0.915        0.925
##    78   8831       6    0.919 0.002728        0.914        0.925
##    79   8821       9    0.918 0.002743        0.913        0.924
##    80   8802       6    0.918 0.002753        0.912        0.923
##    81   8784       4    0.917 0.002759        0.912        0.923
##    82   8774      11    0.916 0.002778        0.911        0.922
##    83   8757       5    0.916 0.002786        0.910        0.921
##    84   8747       7    0.915 0.002797        0.909        0.920
##    85   8729       6    0.914 0.002807        0.909        0.920
##    86   8713       8    0.913 0.002820        0.908        0.919
##    87   8697       8    0.913 0.002833        0.907        0.918
##    88   8683       3    0.912 0.002838        0.907        0.918
##    89   8675      14    0.911 0.002861        0.905        0.916
##    90   8653       7    0.910 0.002872        0.904        0.916
##    91   8642       6    0.909 0.002882        0.904        0.915
##    92   8632       5    0.909 0.002889        0.903        0.915
##    93   8621       7    0.908 0.002901        0.903        0.914
##    94   8603       9    0.907 0.002915        0.902        0.913
##    95   8591      10    0.906 0.002930        0.900        0.912
##    96   8572       6    0.906 0.002940        0.900        0.911
##    97   8561       6    0.905 0.002949        0.899        0.911
##    98   8547       5    0.904 0.002957        0.899        0.910
##    99   8532       8    0.904 0.002969        0.898        0.909
##   100   8513       6    0.903 0.002979        0.897        0.909
##   101   8503       6    0.902 0.002988        0.896        0.908
##   102   8491       4    0.902 0.002994        0.896        0.908
##   103   8478       3    0.901 0.002999        0.896        0.907
##   104   8469       8    0.901 0.003011        0.895        0.907
##   105   8451       3    0.900 0.003015        0.894        0.906
##   106   8438      11    0.899 0.003032        0.893        0.905
##   107   8420       8    0.898 0.003044        0.892        0.904
##   108   8407       5    0.898 0.003052        0.892        0.904
##   109   8397       6    0.897 0.003061        0.891        0.903
##   110   8386       6    0.896 0.003070        0.890        0.903
##   111   8376       1    0.896 0.003071        0.890        0.902
##   112   8367       6    0.896 0.003080        0.890        0.902
##   113   8354       6    0.895 0.003089        0.889        0.901
##   114   8342       4    0.895 0.003095        0.889        0.901
##   115   8330       4    0.894 0.003101        0.888        0.900
##   116   8320      10    0.893 0.003116        0.887        0.899
##   117   8305       7    0.892 0.003126        0.886        0.899
##   118   8290       8    0.892 0.003138        0.885        0.898
##   119   8279       5    0.891 0.003145        0.885        0.897
##   120   8270       4    0.891 0.003151        0.884        0.897
##   121   8259       5    0.890 0.003159        0.884        0.896
##   122   8250       8    0.889 0.003170        0.883        0.895
##   123   8237      11    0.888 0.003186        0.882        0.894
##   124   8222       7    0.887 0.003196        0.881        0.894
##   125   8210       2    0.887 0.003199        0.881        0.893
##   126   8204       7    0.886 0.003209        0.880        0.893
##   127   8190       5    0.886 0.003216        0.879        0.892
##   128   8181       7    0.885 0.003226        0.879        0.891
##   129   8168       6    0.884 0.003235        0.878        0.891
##   130   8156       7    0.884 0.003245        0.877        0.890
##   131   8140       6    0.883 0.003253        0.877        0.889
##   132   8132      11    0.882 0.003269        0.875        0.888
##   133   8115       5    0.881 0.003276        0.875        0.888
##   134   8108       8    0.880 0.003287        0.874        0.887
##   135   8097       3    0.880 0.003291        0.874        0.886
##   136   8085       6    0.879 0.003299        0.873        0.886
##   137   8074       8    0.878 0.003310        0.872        0.885
##   138   8061       6    0.878 0.003319        0.871        0.884
##   139   8044      10    0.877 0.003333        0.870        0.883
##   140   8029       8    0.876 0.003343        0.869        0.882
##   141   8018       4    0.875 0.003349        0.869        0.882
##   142   8012       5    0.875 0.003356        0.868        0.881
##   143   8001       2    0.875 0.003358        0.868        0.881
##   144   7997       5    0.874 0.003365        0.867        0.881
##   145   7989      11    0.873 0.003380        0.866        0.880
##   146   7975       8    0.872 0.003391        0.865        0.879
##   147   7962       9    0.871 0.003403        0.864        0.878
##   148   7945       7    0.870 0.003412        0.864        0.877
##   149   7934       9    0.869 0.003424        0.863        0.876
##   150   7919       8    0.868 0.003435        0.862        0.875
##   151   7901       1    0.868 0.003436        0.862        0.875
##   152   7894       5    0.868 0.003443        0.861        0.874
##   153   7885       5    0.867 0.003449        0.860        0.874
##   154   7875       4    0.867 0.003455        0.860        0.874
##   155   7868       4    0.866 0.003460        0.860        0.873
##   156   7864       4    0.866 0.003465        0.859        0.873
##   157   7858       6    0.865 0.003473        0.858        0.872
##   158   7850       6    0.865 0.003481        0.858        0.871
##   159   7839       3    0.864 0.003485        0.857        0.871
##   160   7829       6    0.864 0.003493        0.857        0.870
##   161   7817       6    0.863 0.003500        0.856        0.870
##   163   7796       8    0.862 0.003511        0.855        0.869
##   164   7784       3    0.862 0.003515        0.855        0.869
##   165   7778       6    0.861 0.003522        0.854        0.868
##   166   7769       6    0.860 0.003530        0.853        0.867
##   167   7760       2    0.860 0.003533        0.853        0.867
##   168   7755       2    0.860 0.003535        0.853        0.867
##   169   7750       9    0.859 0.003547        0.852        0.866
##   170   7732       5    0.858 0.003553        0.851        0.865
##   171   7724       1    0.858 0.003554        0.851        0.865
##   172   7717       7    0.857 0.003563        0.850        0.864
##   173   7706       5    0.857 0.003570        0.850        0.864
##   174   7696       6    0.856 0.003577        0.849        0.863
##   175   7687       7    0.855 0.003586        0.848        0.862
##   176   7674       5    0.855 0.003592        0.848        0.862
##   177   7667       4    0.854 0.003598        0.847        0.861
##   178   7656       6    0.854 0.003605        0.847        0.861
##   180   7644       4    0.853 0.003610        0.846        0.860
##   181   7635       3    0.853 0.003614        0.846        0.860
##   182   7626       4    0.853 0.003619        0.845        0.860
##   183   7616       4    0.852 0.003624        0.845        0.859
##   184   7607       2    0.852 0.003626        0.845        0.859
##   185   7602       4    0.851 0.003631        0.844        0.859
##   186   7593       6    0.851 0.003639        0.844        0.858
##   187   7585       1    0.851 0.003640        0.844        0.858
##   188   7582       4    0.850 0.003645        0.843        0.857
##   189   7574       6    0.849 0.003653        0.842        0.857
##   190   7563       5    0.849 0.003659        0.842        0.856
##   191   7554       2    0.849 0.003661        0.842        0.856
##   192   7551       5    0.848 0.003667        0.841        0.855
##   193   7546       1    0.848 0.003669        0.841        0.855
##   194   7543       5    0.847 0.003675        0.840        0.855
##   195   7536       6    0.847 0.003682        0.840        0.854
##   196   7528       5    0.846 0.003688        0.839        0.853
##   197   7521       2    0.846 0.003691        0.839        0.853
##   198   7515      11    0.845 0.003704        0.838        0.852
##   199   7501       2    0.845 0.003707        0.837        0.852
##   200   7498       3    0.844 0.003710        0.837        0.852
##   201   7493       2    0.844 0.003713        0.837        0.851
##   202   7489       6    0.843 0.003720        0.836        0.851
##   203   7481       2    0.843 0.003723        0.836        0.850
##   204   7475       8    0.842 0.003732        0.835        0.850
##   205   7462       2    0.842 0.003735        0.835        0.849
##   206   7456       4    0.842 0.003739        0.834        0.849
##   207   7449       1    0.841 0.003741        0.834        0.849
##   208   7447       1    0.841 0.003742        0.834        0.849
##   209   7442       2    0.841 0.003744        0.834        0.848
##   210   7434       2    0.841 0.003747        0.834        0.848
##   211   7427       6    0.840 0.003754        0.833        0.848
##   212   7411       5    0.840 0.003760        0.832        0.847
##   213   7402       9    0.839 0.003771        0.831        0.846
##   214   7390       6    0.838 0.003778        0.831        0.845
##   215   7377       3    0.838 0.003781        0.830        0.845
##   216   7369       5    0.837 0.003787        0.830        0.844
##   217   7360       7    0.836 0.003796        0.829        0.844
##   218   7350       7    0.835 0.003804        0.828        0.843
##   219   7340       4    0.835 0.003809        0.827        0.842
##   220   7333       4    0.834 0.003813        0.827        0.842
##   221   7328       3    0.834 0.003817        0.827        0.842
##   222   7322       3    0.834 0.003821        0.826        0.841
##   223   7312       2    0.834 0.003823        0.826        0.841
##   224   7306       4    0.833 0.003828        0.826        0.841
##   225   7298       1    0.833 0.003829        0.826        0.841
##   226   7293       4    0.833 0.003833        0.825        0.840
##   227   7287       4    0.832 0.003838        0.825        0.840
##   228   7282       6    0.831 0.003845        0.824        0.839
##   229   7271       6    0.831 0.003852        0.823        0.838
##   230   7262       5    0.830 0.003858        0.823        0.838
##   231   7254       5    0.830 0.003864        0.822        0.837
##   232   7247       8    0.829 0.003873        0.821        0.836
##   233   7232       6    0.828 0.003880        0.820        0.836
##   234   7216       3    0.828 0.003884        0.820        0.835
##   235   7208       2    0.827 0.003886        0.820        0.835
##   236   7204       6    0.827 0.003893        0.819        0.834
##   237   7197       5    0.826 0.003899        0.819        0.834
##   238   7188       5    0.826 0.003904        0.818        0.833
##   239   7180       5    0.825 0.003910        0.817        0.833
##   240   7171       3    0.825 0.003913        0.817        0.832
##   241   7166       2    0.824 0.003916        0.817        0.832
##   242   7157       6    0.824 0.003923        0.816        0.831
##   243   7149       3    0.823 0.003926        0.816        0.831
##   244   7145       6    0.823 0.003933        0.815        0.830
##   245   7134       2    0.822 0.003935        0.815        0.830
##   246   7127       5    0.822 0.003941        0.814        0.830
##   247   7121       6    0.821 0.003948        0.813        0.829
##   248   7111       3    0.821 0.003951        0.813        0.829
##   249   7106       6    0.820 0.003958        0.812        0.828
##   250   7096       5    0.820 0.003964        0.812        0.827
##   251   7088       3    0.819 0.003967        0.811        0.827
##   252   7082       4    0.819 0.003971        0.811        0.827
##   253   7074       2    0.818 0.003974        0.811        0.826
##   254   7062       5    0.818 0.003979        0.810        0.826
##   255   7053       4    0.817 0.003984        0.810        0.825
##   256   7047       4    0.817 0.003988        0.809        0.825
##   257   7040       6    0.816 0.003995        0.809        0.824
##   258   7031       4    0.816 0.003999        0.808        0.824
##   259   7020       7    0.815 0.004007        0.807        0.823
##   260   7012       5    0.814 0.004013        0.807        0.822
##   261   7006       6    0.814 0.004019        0.806        0.822
##   262   6999       5    0.813 0.004025        0.805        0.821
##   263   6992       2    0.813 0.004027        0.805        0.821
##   264   6989       1    0.813 0.004028        0.805        0.821
##   265   6983       2    0.813 0.004031        0.805        0.821
##   266   6976       4    0.812 0.004035        0.804        0.820
##   267   6971       5    0.812 0.004040        0.804        0.819
##   268   6963       4    0.811 0.004045        0.803        0.819
##   269   6957       2    0.811 0.004047        0.803        0.819
##   270   6952       3    0.810 0.004050        0.803        0.818
##   271   6947       2    0.810 0.004053        0.802        0.818
##   272   6939       7    0.809 0.004060        0.802        0.817
##   273   6928       2    0.809 0.004062        0.801        0.817
##   274   6924       6    0.808 0.004069        0.801        0.817
##   275   6917       3    0.808 0.004072        0.800        0.816
##   276   6910       2    0.808 0.004074        0.800        0.816
##   277   6908       4    0.807 0.004079        0.799        0.815
##   278   6901       6    0.807 0.004085        0.799        0.815
##   279   6893       3    0.806 0.004088        0.798        0.814
##   280   6886       5    0.806 0.004094        0.798        0.814
##   281   6880       3    0.805 0.004097        0.797        0.814
##   282   6874       5    0.805 0.004103        0.797        0.813
##   283   6868       4    0.804 0.004107        0.796        0.812
##   284   6861       1    0.804 0.004108        0.796        0.812
##   285   6859       2    0.804 0.004110        0.796        0.812
##   286   6855       2    0.804 0.004112        0.796        0.812
##   287   6848       2    0.804 0.004114        0.796        0.812
##   288   6838       3    0.803 0.004118        0.795        0.811
##   289   6830       7    0.802 0.004125        0.794        0.811
##   290   6821       3    0.802 0.004128        0.794        0.810
##   291   6818       4    0.802 0.004133        0.794        0.810
##   292   6812       4    0.801 0.004137        0.793        0.809
##   293   6805       5    0.801 0.004142        0.792        0.809
##   294   6796       3    0.800 0.004145        0.792        0.808
##   295   6790       4    0.800 0.004150        0.792        0.808
##   296   6785       3    0.799 0.004153        0.791        0.808
##   297   6778       2    0.799 0.004155        0.791        0.807
##   298   6773       3    0.799 0.004158        0.791        0.807
##   299   6767       5    0.798 0.004163        0.790        0.806
##   300   6762       7    0.797 0.004171        0.789        0.806
##   301   6752       3    0.797 0.004174        0.789        0.805
##   302   6745       3    0.797 0.004177        0.788        0.805
##   303   6739       3    0.796 0.004180        0.788        0.805
##   304   6733       1    0.796 0.004181        0.788        0.804
##   305   6730       4    0.796 0.004186        0.788        0.804
##   306   6724       4    0.795 0.004190        0.787        0.803
##   307   6719       2    0.795 0.004192        0.787        0.803
##   308   6714       3    0.795 0.004195        0.786        0.803
##   309   6709       3    0.794 0.004198        0.786        0.803
##   310   6705       4    0.794 0.004202        0.786        0.802
##   311   6700       1    0.794 0.004203        0.785        0.802
##   312   6697       8    0.793 0.004212        0.785        0.801
##   313   6687       2    0.792 0.004214        0.784        0.801
##   314   6684       4    0.792 0.004218        0.784        0.800
##   315   6679       1    0.792 0.004219        0.784        0.800
##   316   6675       6    0.791 0.004225        0.783        0.799
##   317   6665       3    0.791 0.004228        0.783        0.799
##   318   6660       2    0.791 0.004230        0.782        0.799
##   319   6657       1    0.790 0.004231        0.782        0.799
##   320   6655       2    0.790 0.004233        0.782        0.799
##   321   6648       2    0.790 0.004235        0.782        0.798
##   322   6644       1    0.790 0.004236        0.782        0.798
##   323   6642       2    0.790 0.004238        0.781        0.798
##   324   6638       1    0.790 0.004240        0.781        0.798
##   325   6632       1    0.789 0.004241        0.781        0.798
##   326   6627       4    0.789 0.004245        0.781        0.797
##   327   6620       2    0.789 0.004247        0.780        0.797
##   328   6615       3    0.788 0.004250        0.780        0.797
##   329   6609       2    0.788 0.004252        0.780        0.796
##   330   6604       4    0.788 0.004256        0.779        0.796
##   331   6599       2    0.787 0.004258        0.779        0.796
##   332   6594       3    0.787 0.004261        0.779        0.795
##   333   6590       1    0.787 0.004262        0.779        0.795
##   334   6585       2    0.787 0.004264        0.778        0.795
##   335   6580       3    0.786 0.004267        0.778        0.795
##   336   6573       6    0.786 0.004273        0.777        0.794
##   337   6561       4    0.785 0.004278        0.777        0.794
##   338   6554       4    0.785 0.004282        0.776        0.793
##   339   6548       2    0.784 0.004284        0.776        0.793
##   340   6546       1    0.784 0.004285        0.776        0.793
##   341   6542       2    0.784 0.004287        0.776        0.792
##   342   6539       2    0.784 0.004289        0.775        0.792
##   343   6533       1    0.784 0.004290        0.775        0.792
##   344   6530       2    0.783 0.004292        0.775        0.792
##   345   6527       2    0.783 0.004294        0.775        0.792
##   346   6523       3    0.783 0.004297        0.774        0.791
##   347   6517       3    0.782 0.004300        0.774        0.791
##   348   6512       2    0.782 0.004302        0.774        0.791
##   349   6510       2    0.782 0.004304        0.774        0.790
##   350   6508       5    0.781 0.004309        0.773        0.790
##   351   6501       1    0.781 0.004310        0.773        0.790
##   352   6498       2    0.781 0.004312        0.773        0.790
##   353   6493       2    0.781 0.004314        0.772        0.789
##   354   6489       5    0.780 0.004319        0.772        0.789
##   355   6483       3    0.780 0.004322        0.771        0.788
##   356   6477       2    0.780 0.004324        0.771        0.788
##   357   6471       3    0.779 0.004327        0.771        0.788
##   358   6465       1    0.779 0.004328        0.771        0.788
##   359   6461       2    0.779 0.004330        0.770        0.787
##   360   6458       2    0.779 0.004332        0.770        0.787
##   361   6454       3    0.778 0.004335        0.770        0.787
##   362   6447       3    0.778 0.004338        0.769        0.786
##   363   6443       3    0.778 0.004341        0.769        0.786
##   364   6437       2    0.777 0.004343        0.769        0.786
##   365   6430       3    0.777 0.004346        0.768        0.785
##   366   6424       2    0.777 0.004348        0.768        0.785
##   367   6420       4    0.776 0.004353        0.768        0.785
##   368   6416       7    0.775 0.004360        0.767        0.784
##   369   6406       3    0.775 0.004363        0.766        0.784
##   371   6397       4    0.774 0.004367        0.766        0.783
##   372   6390       3    0.774 0.004370        0.766        0.783
##   373   6387       2    0.774 0.004371        0.765        0.783
##   374   6381       3    0.774 0.004374        0.765        0.782
##   375   6377       1    0.773 0.004375        0.765        0.782
##   376   6375       3    0.773 0.004378        0.765        0.782
##   377   6370       2    0.773 0.004380        0.764        0.781
##   379   6362       5    0.772 0.004385        0.764        0.781
##   380   6355       1    0.772 0.004386        0.764        0.781
##   381   6354       2    0.772 0.004388        0.763        0.780
##   382   6349       2    0.772 0.004390        0.763        0.780
##   383   6344       3    0.771 0.004393        0.763        0.780
##   384   6341       2    0.771 0.004395        0.762        0.780
##   386   6332       5    0.770 0.004400        0.762        0.779
##   387   6324       4    0.770 0.004404        0.761        0.779
##   388   6318       4    0.769 0.004408        0.761        0.778
##   389   6311       4    0.769 0.004412        0.760        0.778
##   390   6304       1    0.769 0.004413        0.760        0.777
##   391   6298       1    0.769 0.004414        0.760        0.777
##   392   6294       4    0.768 0.004418        0.760        0.777
##   393   6288       3    0.768 0.004421        0.759        0.777
##   394   6284       7    0.767 0.004428        0.758        0.776
##   395   6274       3    0.767 0.004431        0.758        0.775
##   396   6270       5    0.766 0.004436        0.757        0.775
##   397   6264       4    0.765 0.004440        0.757        0.774
##   398   6258       2    0.765 0.004442        0.757        0.774
##   400   6251       1    0.765 0.004443        0.756        0.774
##   401   6250       5    0.764 0.004447        0.756        0.773
##   402   6243       3    0.764 0.004450        0.755        0.773
##   403   6239       2    0.764 0.004452        0.755        0.773
##   404   6235       4    0.763 0.004456        0.755        0.772
##   405   6230       2    0.763 0.004458        0.754        0.772
##   406   6224       1    0.763 0.004459        0.754        0.772
##   407   6218       1    0.763 0.004460        0.754        0.772
##   408   6215       3    0.763 0.004463        0.754        0.771
##   409   6210       1    0.762 0.004464        0.754        0.771
##   410   6207       3    0.762 0.004467        0.753        0.771
##   411   6203       3    0.762 0.004470        0.753        0.770
##   412   6199       4    0.761 0.004474        0.752        0.770
##   413   6193       1    0.761 0.004475        0.752        0.770
##   414   6191       5    0.760 0.004479        0.752        0.769
##   415   6182       2    0.760 0.004481        0.751        0.769
##   416   6174       2    0.760 0.004483        0.751        0.769
##   418   6167       3    0.760 0.004486        0.751        0.768
##   419   6162       2    0.759 0.004488        0.751        0.768
##   421   6159       1    0.759 0.004489        0.750        0.768
##   422   6153       1    0.759 0.004490        0.750        0.768
##   423   6151       4    0.759 0.004494        0.750        0.767
##   424   6146       3    0.758 0.004497        0.749        0.767
##   425   6141       1    0.758 0.004498        0.749        0.767
##   428   6132       3    0.758 0.004501        0.749        0.767
##   430   6118       4    0.757 0.004504        0.748        0.766
##   431   6110       3    0.757 0.004507        0.748        0.766
##   432   6106       1    0.757 0.004508        0.748        0.766
##   434   6101       3    0.756 0.004511        0.748        0.765
##   435   6091       2    0.756 0.004513        0.747        0.765
##   436   6085       5    0.756 0.004518        0.747        0.764
##   438   6078       1    0.755 0.004519        0.747        0.764
##   440   6074       3    0.755 0.004522        0.746        0.764
##   441   6069       1    0.755 0.004523        0.746        0.764
##   442   6065       3    0.755 0.004526        0.746        0.763
##   443   6056       1    0.754 0.004527        0.746        0.763
##   444   6052       2    0.754 0.004529        0.745        0.763
##   445   6046       5    0.754 0.004533        0.745        0.762
##   446   6038       3    0.753 0.004536        0.744        0.762
##   447   6033       2    0.753 0.004538        0.744        0.762
##   448   6029       2    0.753 0.004540        0.744        0.762
##   449   6025       4    0.752 0.004544        0.743        0.761
##   450   6017       1    0.752 0.004545        0.743        0.761
##   451   6013       3    0.752 0.004548        0.743        0.761
##   452   6009       1    0.752 0.004549        0.743        0.760
##   453   6004       3    0.751 0.004552        0.742        0.760
##   455   5997       4    0.751 0.004556        0.742        0.760
##   457   5983       2    0.750 0.004558        0.742        0.759
##   458   5975       1    0.750 0.004559        0.741        0.759
##   459   5970       3    0.750 0.004561        0.741        0.759
##   460   5951       2    0.750 0.004563        0.741        0.759
##   462   5934       3    0.749 0.004566        0.740        0.758
##   463   5925       4    0.749 0.004570        0.740        0.758
##   464   5912       1    0.749 0.004571        0.740        0.758
##   465   5906       4    0.748 0.004575        0.739        0.757
##   466   5889       1    0.748 0.004576        0.739        0.757
##   468   5864       2    0.748 0.004578        0.739        0.757
##   469   5857       2    0.747 0.004580        0.739        0.757
##   470   5839       1    0.747 0.004581        0.738        0.756
##   471   5830       2    0.747 0.004583        0.738        0.756
##   472   5814       4    0.747 0.004587        0.738        0.756
##   473   5792       4    0.746 0.004591        0.737        0.755
##   474   5782       3    0.746 0.004594        0.737        0.755
##   475   5771       1    0.746 0.004595        0.737        0.755
##   476   5767       1    0.745 0.004596        0.736        0.754
##   479   5732       4    0.745 0.004601        0.736        0.754
##   480   5716       5    0.744 0.004606        0.735        0.753
##   481   5701       4    0.744 0.004610        0.735        0.753
##   482   5688       5    0.743 0.004615        0.734        0.752
##   483   5678       1    0.743 0.004616        0.734        0.752
##   484   5664       4    0.742 0.004620        0.733        0.752
##   485   5653       1    0.742 0.004621        0.733        0.751
##   486   5641       2    0.742 0.004623        0.733        0.751
##   488   5631       4    0.741 0.004628        0.732        0.751
##   489   5623       3    0.741 0.004631        0.732        0.750
##   491   5604       4    0.741 0.004635        0.732        0.750
##   492   5591       1    0.740 0.004636        0.731        0.750
##   493   5575       1    0.740 0.004637        0.731        0.749
##   494   5561       1    0.740 0.004638        0.731        0.749
##   495   5543       1    0.740 0.004639        0.731        0.749
##   498   5511       2    0.740 0.004642        0.731        0.749
##   499   5496       1    0.740 0.004643        0.731        0.749
##   500   5489       3    0.739 0.004646        0.730        0.748
##   502   5464       1    0.739 0.004647        0.730        0.748
##   503   5445       2    0.739 0.004649        0.730        0.748
##   504   5436       1    0.739 0.004651        0.730        0.748
##   505   5422       1    0.739 0.004652        0.729        0.748
##   506   5405       1    0.738 0.004653        0.729        0.748
##   507   5390       1    0.738 0.004654        0.729        0.747
##   508   5377       2    0.738 0.004656        0.729        0.747
##   509   5366       2    0.738 0.004659        0.729        0.747
##   510   5356       1    0.738 0.004660        0.729        0.747
##   511   5348       2    0.737 0.004662        0.728        0.747
##   512   5333       1    0.737 0.004663        0.728        0.746
##   514   5315       2    0.737 0.004666        0.728        0.746
##   515   5300       1    0.737 0.004667        0.728        0.746
##   516   5289       1    0.737 0.004668        0.728        0.746
##   517   5276       1    0.736 0.004669        0.727        0.746
##   520   5247       1    0.736 0.004670        0.727        0.746
##   521   5233       2    0.736 0.004673        0.727        0.745
##   522   5222       1    0.736 0.004674        0.727        0.745
##   523   5211       3    0.735 0.004678        0.726        0.745
##   525   5200       3    0.735 0.004682        0.726        0.744
##   526   5185       1    0.735 0.004683        0.726        0.744
##   528   5166       3    0.734 0.004687        0.725        0.744
##   529   5147       1    0.734 0.004688        0.725        0.744
##   530   5123       1    0.734 0.004689        0.725        0.743
##   532   5105       1    0.734 0.004690        0.725        0.743
##   536   5061       1    0.734 0.004692        0.725        0.743
##   537   5049       1    0.734 0.004693        0.725        0.743
##   538   5040       1    0.734 0.004694        0.724        0.743
##   539   5032       1    0.733 0.004696        0.724        0.743
##   540   5020       1    0.733 0.004697        0.724        0.743
##   541   5011       1    0.733 0.004698        0.724        0.742
##   543   4989       1    0.733 0.004700        0.724        0.742
##   544   4980       3    0.733 0.004704        0.723        0.742
##   547   4953       5    0.732 0.004711        0.723        0.741
##   548   4938       1    0.732 0.004712        0.723        0.741
##   550   4914       2    0.731 0.004715        0.722        0.741
##   551   4897       4    0.731 0.004720        0.722        0.740
##   553   4881       1    0.731 0.004722        0.721        0.740
##   554   4871       1    0.731 0.004723        0.721        0.740
##   555   4862       1    0.730 0.004725        0.721        0.740
##   556   4848       2    0.730 0.004728        0.721        0.739
##   557   4835       1    0.730 0.004729        0.721        0.739
##   561   4792       3    0.729 0.004733        0.720        0.739
##   564   4750       1    0.729 0.004735        0.720        0.739
##   565   4735       3    0.729 0.004739        0.720        0.738
##   566   4725       2    0.729 0.004742        0.719        0.738
##   567   4720       1    0.728 0.004744        0.719        0.738
##   568   4712       1    0.728 0.004745        0.719        0.738
##   569   4703       1    0.728 0.004747        0.719        0.737
##   570   4694       2    0.728 0.004750        0.719        0.737
##   571   4684       3    0.727 0.004755        0.718        0.737
##   572   4674       3    0.727 0.004759        0.718        0.736
##   573   4667       1    0.727 0.004761        0.717        0.736
##   574   4657       2    0.726 0.004764        0.717        0.736
##   576   4639       2    0.726 0.004767        0.717        0.735
##   577   4631       1    0.726 0.004768        0.717        0.735
##   578   4630       2    0.726 0.004771        0.716        0.735
##   579   4626       4    0.725 0.004778        0.716        0.734
##   581   4611       2    0.725 0.004781        0.715        0.734
##   582   4604       1    0.724 0.004782        0.715        0.734
##   584   4585       1    0.724 0.004784        0.715        0.734
##   587   4557       1    0.724 0.004785        0.715        0.734
##   588   4548       1    0.724 0.004787        0.715        0.733
##   589   4541       1    0.724 0.004789        0.715        0.733
##   590   4533       1    0.724 0.004790        0.714        0.733
##   593   4502       1    0.724 0.004792        0.714        0.733
##   595   4492       1    0.723 0.004793        0.714        0.733
##   596   4485       1    0.723 0.004795        0.714        0.733
##   598   4466       1    0.723 0.004797        0.714        0.733
##   600   4447       1    0.723 0.004798        0.714        0.732
##   601   4443       2    0.723 0.004802        0.713        0.732
##   602   4439       2    0.722 0.004805        0.713        0.732
##   603   4431       1    0.722 0.004807        0.713        0.732
##   604   4420       1    0.722 0.004809        0.713        0.731
##   605   4405       1    0.722 0.004810        0.712        0.731
##   606   4393       2    0.721 0.004814        0.712        0.731
##   607   4382       3    0.721 0.004819        0.712        0.730
##   609   4366       3    0.720 0.004824        0.711        0.730
##   613   4320       1    0.720 0.004826        0.711        0.730
##   614   4306       2    0.720 0.004829        0.711        0.729
##   616   4292       1    0.720 0.004831        0.710        0.729
##   617   4284       1    0.720 0.004833        0.710        0.729
##   618   4271       1    0.719 0.004835        0.710        0.729
##   619   4267       1    0.719 0.004836        0.710        0.729
##   622   4237       1    0.719 0.004838        0.710        0.729
##   624   4214       1    0.719 0.004840        0.709        0.728
##   625   4208       1    0.719 0.004842        0.709        0.728
##   626   4202       1    0.719 0.004844        0.709        0.728
##   627   4189       1    0.718 0.004846        0.709        0.728
##   628   4178       1    0.718 0.004848        0.709        0.728
##   629   4171       2    0.718 0.004851        0.708        0.727
##   630   4164       1    0.718 0.004853        0.708        0.727
##   631   4155       1    0.718 0.004855        0.708        0.727
##   632   4142       2    0.717 0.004859        0.708        0.727
##   636   4104       2    0.717 0.004863        0.707        0.726
##   638   4090       1    0.717 0.004865        0.707        0.726
##   640   4071       2    0.716 0.004869        0.707        0.726
##   642   4051       2    0.716 0.004873        0.706        0.726
##   643   4042       3    0.715 0.004879        0.706        0.725
##   644   4034       1    0.715 0.004881        0.706        0.725
##   645   4029       3    0.715 0.004887        0.705        0.724
##   646   4013       1    0.715 0.004889        0.705        0.724
##   647   4001       2    0.714 0.004893        0.705        0.724
##   648   3983       1    0.714 0.004895        0.704        0.724
##   649   3972       2    0.714 0.004899        0.704        0.723
##   650   3963       1    0.713 0.004901        0.704        0.723
##   651   3952       1    0.713 0.004903        0.704        0.723
##   652   3942       2    0.713 0.004908        0.703        0.723
##   653   3934       2    0.713 0.004912        0.703        0.722
##   657   3892       2    0.712 0.004916        0.703        0.722
##   659   3872       1    0.712 0.004918        0.702        0.722
##   661   3851       1    0.712 0.004921        0.702        0.722
##   662   3845       3    0.711 0.004927        0.702        0.721
##   664   3832       1    0.711 0.004929        0.701        0.721
##   665   3825       1    0.711 0.004932        0.701        0.721
##   668   3793       2    0.711 0.004936        0.701        0.720
##   670   3763       2    0.710 0.004941        0.701        0.720
##   671   3751       1    0.710 0.004943        0.700        0.720
##   673   3733       1    0.710 0.004945        0.700        0.720
##   674   3721       1    0.710 0.004948        0.700        0.719
##   676   3701       2    0.709 0.004952        0.700        0.719
##   679   3687       2    0.709 0.004957        0.699        0.719
##   680   3680       4    0.708 0.004967        0.698        0.718
##   685   3638       2    0.708 0.004972        0.698        0.717
##   686   3631       1    0.707 0.004974        0.698        0.717
##   688   3618       1    0.707 0.004977        0.698        0.717
##   689   3609       1    0.707 0.004979        0.697        0.717
##   690   3595       1    0.707 0.004982        0.697        0.717
##   691   3586       2    0.706 0.004987        0.697        0.716
##   692   3579       1    0.706 0.004989        0.697        0.716
##   694   3567       1    0.706 0.004992        0.696        0.716
##   695   3558       3    0.705 0.004999        0.696        0.715
##   696   3547       2    0.705 0.005004        0.695        0.715
##   697   3531       1    0.705 0.005007        0.695        0.715
##   698   3518       1    0.705 0.005009        0.695        0.715
##   701   3492       2    0.704 0.005015        0.695        0.714
##   702   3481       1    0.704 0.005017        0.694        0.714
##   703   3472       3    0.703 0.005025        0.694        0.713
##   705   3457       3    0.703 0.005033        0.693        0.713
##   706   3446       2    0.702 0.005039        0.693        0.712
##   710   3414       1    0.702 0.005041        0.692        0.712
##   711   3404       1    0.702 0.005044        0.692        0.712
##   712   3393       1    0.702 0.005047        0.692        0.712
##   713   3389       1    0.702 0.005050        0.692        0.712
##   715   3376       1    0.701 0.005052        0.692        0.711
##   716   3368       1    0.701 0.005055        0.691        0.711
##   717   3351       1    0.701 0.005058        0.691        0.711
##   718   3343       1    0.701 0.005061        0.691        0.711
##   719   3333       1    0.701 0.005064        0.691        0.711
##   720   3329       1    0.700 0.005066        0.690        0.710
##   722   3316       1    0.700 0.005069        0.690        0.710
##   724   3295       1    0.700 0.005072        0.690        0.710
##   726   3264       3    0.699 0.005081        0.689        0.709
##   728   3254       2    0.699 0.005087        0.689        0.709
##   732   3224       2    0.698 0.005093        0.689        0.708
##   733   3210       1    0.698 0.005096        0.688        0.708
##   736   3193       1    0.698 0.005099        0.688        0.708
##   739   3164       2    0.698 0.005106        0.688        0.708
##   741   3144       2    0.697 0.005112        0.687        0.707
##   742   3136       1    0.697 0.005115        0.687        0.707
##   743   3130       1    0.697 0.005118        0.687        0.707
##   746   3104       1    0.696 0.005122        0.686        0.707
##   747   3095       3    0.696 0.005132        0.686        0.706
##   748   3084       3    0.695 0.005141        0.685        0.705
##   749   3079       2    0.695 0.005148        0.685        0.705
##   751   3065       1    0.694 0.005151        0.684        0.705
##   754   3039       2    0.694 0.005158        0.684        0.704
##   755   3031       2    0.693 0.005165        0.683        0.704
##   756   3025       2    0.693 0.005172        0.683        0.703
##   759   2999       1    0.693 0.005175        0.683        0.703
##   760   2991       3    0.692 0.005185        0.682        0.702
##   762   2969       1    0.692 0.005189        0.682        0.702
##   767   2922       1    0.692 0.005192        0.682        0.702
##   768   2913       2    0.691 0.005200        0.681        0.701
##   770   2903       2    0.691 0.005207        0.681        0.701
##   771   2896       1    0.690 0.005211        0.680        0.701
##   772   2884       1    0.690 0.005214        0.680        0.701
##   775   2852       1    0.690 0.005218        0.680        0.700
##   776   2843       1    0.690 0.005222        0.680        0.700
##   777   2840       1    0.689 0.005226        0.679        0.700
##   779   2818       3    0.689 0.005237        0.679        0.699
##   781   2792       1    0.689 0.005241        0.678        0.699
##   785   2763       1    0.688 0.005245        0.678        0.699
##   794   2672       1    0.688 0.005250        0.678        0.698
##   796   2655       1    0.688 0.005254        0.678        0.698
##   797   2648       1    0.687 0.005259        0.677        0.698
##   803   2600       1    0.687 0.005263        0.677        0.698
##   804   2596       2    0.687 0.005272        0.676        0.697
##   808   2566       1    0.686 0.005277        0.676        0.697
##   809   2555       1    0.686 0.005282        0.676        0.697
##   811   2541       4    0.685 0.005301        0.675        0.696
##   812   2530       1    0.685 0.005306        0.674        0.695
##   824   2433       1    0.685 0.005311        0.674        0.695
##   827   2415       1    0.684 0.005317        0.674        0.695
##   830   2393       2    0.684 0.005327        0.673        0.694
##   831   2378       1    0.683 0.005333        0.673        0.694
##   833   2366       1    0.683 0.005339        0.673        0.694
##   834   2354       2    0.683 0.005350        0.672        0.693
##   835   2345       1    0.682 0.005355        0.672        0.693
##   844   2263       1    0.682 0.005362        0.671        0.692
##   846   2250       1    0.682 0.005368        0.671        0.692
##   847   2240       1    0.681 0.005374        0.671        0.692
##   848   2228       2    0.681 0.005386        0.670        0.691
##   850   2212       1    0.680 0.005393        0.670        0.691
##   852   2192       1    0.680 0.005399        0.670        0.691
##   859   2147       1    0.680 0.005406        0.669        0.690
##   864   2122       1    0.679 0.005413        0.669        0.690
##   866   2104       1    0.679 0.005420        0.669        0.690
##   867   2100       1    0.679 0.005427        0.668        0.690
##   869   2089       1    0.678 0.005434        0.668        0.689
##   873   2060       1    0.678 0.005442        0.668        0.689
##   875   2053       1    0.678 0.005449        0.667        0.689
##   876   2041       1    0.677 0.005456        0.667        0.688
##   877   2033       1    0.677 0.005464        0.667        0.688
##   878   2020       1    0.677 0.005471        0.666        0.688
##   880   2006       1    0.676 0.005479        0.666        0.687
##   881   2000       1    0.676 0.005487        0.665        0.687
##   883   1992       1    0.676 0.005494        0.665        0.687
##   884   1985       1    0.675 0.005502        0.665        0.686
##   889   1956       1    0.675 0.005510        0.664        0.686
##   890   1946       1    0.675 0.005518        0.664        0.686
##   892   1932       1    0.674 0.005527        0.664        0.685
##   893   1919       1    0.674 0.005535        0.663        0.685
##   894   1908       2    0.673 0.005552        0.663        0.684
##   895   1899       1    0.673 0.005560        0.662        0.684
##   900   1871       1    0.673 0.005569        0.662        0.684
##   903   1853       1    0.672 0.005577        0.661        0.683
##   904   1845       1    0.672 0.005586        0.661        0.683
##   907   1820       1    0.672 0.005595        0.661        0.683
##   913   1755       1    0.671 0.005605        0.660        0.682
##   915   1730       1    0.671 0.005615        0.660        0.682
##   922   1676       1    0.670 0.005626        0.659        0.681
##   926   1657       2    0.670 0.005649        0.659        0.681
##   927   1650       1    0.669 0.005660        0.658        0.680
##   934   1588       1    0.669 0.005672        0.658        0.680
##   936   1562       3    0.667 0.005709        0.656        0.679
##   942   1518       1    0.667 0.005722        0.656        0.678
##   943   1516       2    0.666 0.005748        0.655        0.677
##   945   1513       2    0.665 0.005774        0.654        0.677
##   946   1507       1    0.665 0.005787        0.654        0.676
##   947   1499       2    0.664 0.005814        0.653        0.675
##   955   1429       3    0.663 0.005857        0.651        0.674
##   958   1399       1    0.662 0.005872        0.651        0.674
##   961   1380       1    0.662 0.005887        0.650        0.673
##   962   1376       1    0.661 0.005902        0.650        0.673
##   970   1322       1    0.661 0.005919        0.649        0.672
##   979   1277       1    0.660 0.005937        0.649        0.672
##   992   1241       1    0.660 0.005956        0.648        0.671
##  1002   1221       1    0.659 0.005976        0.647        0.671
##  1022   1180       1    0.658 0.005997        0.647        0.670
##  1024   1174       1    0.658 0.006018        0.646        0.670
##  1025   1169       1    0.657 0.006039        0.646        0.669
##  1026   1165       1    0.657 0.006060        0.645        0.669
##  1028   1161       1    0.656 0.006081        0.644        0.668
##  1038   1122       1    0.656 0.006104        0.644        0.668
##  1040   1099       1    0.655 0.006127        0.643        0.667
##  1045   1065       1    0.654 0.006152        0.642        0.667
##  1048   1045       1    0.654 0.006178        0.642        0.666
##  1053   1014       1    0.653 0.006206        0.641        0.665
##  1069    877       1    0.652 0.006243        0.640        0.665
##  1078    823       1    0.652 0.006286        0.639        0.664
##  1082    784       1    0.651 0.006332        0.638        0.663
##  1092    703       1    0.650 0.006391        0.637        0.662
##  1116    524       1    0.649 0.006498        0.636        0.661
##  1133    386       1    0.647 0.006694        0.634        0.660
##  1140    324       1    0.645 0.006965        0.631        0.659
```

```r
plot(fit0, xlab="Time at risk of recidivism in Days", 
   ylab="% not rearrested", yscale=100,
   main ="Survival Distribution (Overall)") 
```

![](compasRecidAlg_files/figure-html/km_curve-1.png)<!-- -->

```r
fitr <- survfit(survobj~race, data=ph)
plot(fitr, xlab="Time at risk of recidivism in Days", 
   ylab="% not rearrested", yscale=100,
   main="Survival Distribution by race",
   col = c('red', 'blue', 'orange', 'yellow', 'green', 'purple')) 
legend('bottomleft', legend=levels(as.factor(ph$race)), col = c('red', 'blue', 'orange', 'yellow', 'green', 'purple'), lty=1)
```

![](compasRecidAlg_files/figure-html/km_curve-2.png)<!-- -->

```r
survdiff(survobj~race, data=ph)
```

```
## Call:
## survdiff(formula = survobj ~ race, data = ph)
## 
##                          N Observed Expected (O-E)^2/E (O-E)^2/V
## race=African-American 5150     1608  1294.09    76.146   143.666
## race=Asian              51        8    16.21     4.159     4.187
## race=Caucasian        3576      815   996.20    32.959    51.627
## race=Hispanic          944      206   275.19    17.397    19.343
## race=Native American    32        6     8.25     0.616     0.618
## race=Other             572      118   171.05    16.453    17.557
## 
##  Chisq= 148  on 5 degrees of freedom, p= <2e-16
```

Note: I haven't used this package in a long time so I needed to look how to use the functions in [documentation](https://cran.r-project.org/web/packages/survival/survival.pdf).  As a consultant, you will probably need to read the documentation a lot.

## Cox proportional hazards model

It is difficult to work with censored data using generalized linear models.
Assuming that each individual hazard function is proportional to some common baseline hazard function makes the problem workable:
\[
\lambda(t|X_i) = \lambda_0(t) \exp(\beta X_i)
\]
where $X_i$ is the covariate vector for participant $i$ and $\beta$ is the parameter vector to be estimated.

Assume $Y_i$ is the response variable.
The likelihood for an observation is
\[
L_i(\beta) = \frac{\lambda(Y_i|X_i)}{\sum_{j:Y_j\geq Y_i} \lambda(Y_i|X_j)} = \frac{\lambda_0(Y_i)\exp(\beta X_i)}{\sum_{j:Y_j\geq Y_i} \lambda_0(Y_i) \exp(\beta X_j)} = \frac{\exp(\beta X_i)}{\sum_{j:Y_j\geq Y_i} \exp(\beta X_j)}.
\]
Notice that the baseline hazard function, $\lambda_0(t)$, cancels.  So, now we can use use an optimization technique to maximize this function.

The joint likelihood is $L(\beta) = \prod_{i: \delta_i=1} L_i(\beta)$ (over the observations with events occuring), with a log-likelihood of 

\[
\ell(\beta) = \sum_{i:\delta_i=1}\left(X_i\beta - \log \sum_{j:Y_j\geq Y_i} X_j\beta \right).
\]

To maximize the likelihood, we can use the Newton-Raphson method.


```r
summary(coxph(survobj~race, data=ph))
```

```
## Call:
## coxph(formula = survobj ~ race, data = ph)
## 
##   n= 10325, number of events= 2761 
## 
##                         coef exp(coef) se(coef)      z Pr(>|z|)    
## raceAsian           -0.92516   0.39647  0.35444 -2.610  0.00905 ** 
## raceCaucasian       -0.41881   0.65783  0.04302 -9.735  < 2e-16 ***
## raceHispanic        -0.50790   0.60176  0.07403 -6.861 6.83e-12 ***
## raceNative American -0.53681   0.58461  0.40901 -1.312  0.18937    
## raceOther           -0.58971   0.55449  0.09540 -6.182 6.34e-10 ***
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
##                     exp(coef) exp(-coef) lower .95 upper .95
## raceAsian              0.3965      2.522    0.1979    0.7942
## raceCaucasian          0.6578      1.520    0.6046    0.7157
## raceHispanic           0.6018      1.662    0.5205    0.6957
## raceNative American    0.5846      1.711    0.2622    1.3032
## raceOther              0.5545      1.803    0.4599    0.6685
## 
## Concordance= 0.56  (se = 0.005 )
## Likelihood ratio test= 149.5  on 5 df,   p=<2e-16
## Wald test            = 145.2  on 5 df,   p=<2e-16
## Score (logrank) test = 148.1  on 5 df,   p=<2e-16
```

```r
summary(coxph(survobj~race+decile_score, data=ph))
```

```
## Call:
## coxph(formula = survobj ~ race + decile_score, data = ph)
## 
##   n= 10325, number of events= 2761 
## 
##                          coef exp(coef)  se(coef)      z Pr(>|z|)    
## raceAsian           -0.455020  0.634435  0.354974 -1.282  0.19990    
## raceCaucasian       -0.123647  0.883692  0.044612 -2.772  0.00558 ** 
## raceHispanic        -0.167138  0.846083  0.075232 -2.222  0.02631 *  
## raceNative American -0.489950  0.612657  0.409016 -1.198  0.23097    
## raceOther           -0.147075  0.863229  0.097131 -1.514  0.12997    
## decile_score         0.179991  1.197207  0.006903 26.074  < 2e-16 ***
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
##                     exp(coef) exp(-coef) lower .95 upper .95
## raceAsian              0.6344     1.5762    0.3164    1.2722
## raceCaucasian          0.8837     1.1316    0.8097    0.9644
## raceHispanic           0.8461     1.1819    0.7301    0.9805
## raceNative American    0.6127     1.6322    0.2748    1.3658
## raceOther              0.8632     1.1584    0.7136    1.0442
## decile_score           1.1972     0.8353    1.1811    1.2135
## 
## Concordance= 0.66  (se = 0.005 )
## Likelihood ratio test= 818.3  on 6 df,   p=<2e-16
## Wald test            = 833.8  on 6 df,   p=<2e-16
## Score (logrank) test = 885.5  on 6 df,   p=<2e-16
```

```r
summary(coxph(survobj~race+age+decile_score, data=ph))
```

```
## Call:
## coxph(formula = survobj ~ race + age + decile_score, data = ph)
## 
##   n= 10325, number of events= 2761 
## 
##                          coef exp(coef)  se(coef)      z Pr(>|z|)    
## raceAsian           -0.463000  0.629393  0.354942 -1.304   0.1921    
## raceCaucasian       -0.109144  0.896601  0.044552 -2.450   0.0143 *  
## raceHispanic        -0.174254  0.840084  0.075181 -2.318   0.0205 *  
## raceNative American -0.494427  0.609920  0.409016 -1.209   0.2267    
## raceOther           -0.163731  0.848970  0.097054 -1.687   0.0916 .  
## age                 -0.010236  0.989817  0.001859 -5.505  3.7e-08 ***
## decile_score         0.167991  1.182926  0.007261 23.137  < 2e-16 ***
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
##                     exp(coef) exp(-coef) lower .95 upper .95
## raceAsian              0.6294     1.5888    0.3139    1.2620
## raceCaucasian          0.8966     1.1153    0.8216    0.9784
## raceHispanic           0.8401     1.1904    0.7250    0.9735
## raceNative American    0.6099     1.6396    0.2736    1.3597
## raceOther              0.8490     1.1779    0.7019    1.0268
## age                    0.9898     1.0103    0.9862    0.9934
## decile_score           1.1829     0.8454    1.1662    1.1999
## 
## Concordance= 0.661  (se = 0.005 )
## Likelihood ratio test= 849.8  on 7 df,   p=<2e-16
## Wald test            = 843  on 7 df,   p=<2e-16
## Score (logrank) test = 897.4  on 7 df,   p=<2e-16
```

## High Level Summary

- Tools like Rmarkdown and Jupyter notebook make code more easily understood and reproducible.
- Always explore the data before running regressions and other statistical tests.  Look at the raw data itself, try to understand variable names, variable distributions, missing data, etc
- Collider bias occurs when conditioning (including as a covariate) on a variable that is influenced by the outcome variable and at least one other covariate.
- Survival analysis tools, such as Kaplan-Meier curves and Cox PH regression, are helpful when follow times leading up to an event vary by observation, especially when censoring occurs.
- When reporting on your analysis, it is important to be aware of possible causal pathways. But, most of the time, it is not possible to use statistical models alone to attribute a causal relationships.
