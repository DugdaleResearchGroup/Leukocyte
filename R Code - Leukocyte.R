#####################################################################
# Social effects on age-related and sex-specific immune cell profiles in a wild mammal
# Original author of script: Sil H.J. van Lieshout
# Date of creation: 28/06/2019
# Script edited by : Sil H.J. van Lieshout
# Last updated: 14/05/2020
####################################################################

# Clean and reading in libraries
rm(list=ls())

library(dplyr)
library(tidyr)
library(purrr)
library(broom)
library(readr)
library(lubridate)
library(ggplot2)
library(lme4)
library(MuMIn)
library(Hmisc)
library(cowplot)
##################################################################

# Data wrangling and plotting

# Read in data
df_leukocyte <- read.csv("Leukocyte - data online.csv")
head(df_leukocyte)
str(df_leukocyte)

# Format classes of the data
df_leukocyte$Tattoo.No <- as.factor(as.character(df_leukocyte$Tattoo.No))
df_leukocyte$Repeat <- as.factor(as.character(df_leukocyte$Repeat))

# Formatting and selecting variables
df_leukocyte <- df_leukocyte %>% 
  filter(NeutProp != "NA") %>%
  mutate(Cohort = DOB) %>% 
  mutate(Year = Date.capture) %>%
  mutate(TotalSGCounts = TotalSGCOunts) %>% 
  dplyr::select(Observation, Tattoo.No, Slide, Repeat, Age.class, SocialGroup, Sex, NeutFreq, NeutProp, LympFreq, LympProp, MonoFreq, EosiFreq, BasoFreq, Age.months, Weight, Body.length, BCI, MaleSGCounts, FemaleSGCounts, TotalSGCounts, SameSexSGCounts, Observation, Cohort, Year, Season)

df_leukocyte$Cohort <- as.factor(as.character(df_leukocyte$Cohort))
df_leukocyte$Year <- as.factor(as.character(df_leukocyte$Year))

df_leukocyte <- df_leukocyte %>% 
  mutate(NeutProp100 = NeutProp/(NeutProp+LympProp)*100) %>% 
  mutate(LympProp100 = LympProp/(NeutProp+LympProp)*100) %>% 
  mutate(NeutLymp = NeutFreq+LympFreq) %>% 
  mutate(LympProp200 = LympFreq/(NeutFreq+LympFreq)*100) %>% 
  mutate(LtoNProp = LympProp100/(LympProp100+NeutProp100))

# Simple plot of the data
ggplot(df_leukocyte, aes(x = Age.months, y = LympProp200)) +
  geom_point() + 
  geom_smooth()
# Strong decrease that levels of - potential log relationship

# Mutate age for log relationship
df_leukocyte <- df_leukocyte %>% 
  mutate(log_Age = log10(Age.months))



##################################################################

# Model preparation

# Model controls
mi.control <- lmerControl(check.conv.grad=.makeCC(action ="ignore", tol=1e-6, relTol=NULL), 
                          optimizer="bobyqa", optCtrl=list(maxfun=100000))

mi.control2 <- glmerControl(check.conv.grad=.makeCC(action ="ignore", tol=1e-6, relTol=NULL), 
                            optimizer="bobyqa", optCtrl=list(maxfun=100000))

df_leukocyte$Slide <- as.factor(df_leukocyte$Slide)

# Testing best age relationship with lymphocyte proportion using AICc

# Response: lymphocyte proportion
# Fixed effects: Age, group size (TotalSGCounts), (Sex)
# Covariates: Season, Year, Body condition index (BCI)
# Random effects: Cohort, Individual ID/Slide (Tattoo.No/Slide), Social Group

# First test whether model overdispersed - and need inclusion of observation-level random effect
# Function to calculate a point estimate of overdispersion from a mixed model object (Harrison 2014)
od.point<-function(modelobject){
  x<-sum(resid(modelobject,type="pearson")^2)
  rdf<-summary(modelobject)$AICtab[5]
  return(x/rdf)
}

# Model
df_leukocyte_male <- df_leukocyte %>% 
  filter(Sex == "male")

Leukocyte_age_bi1 <- glmer(cbind(LympFreq, NeutFreq) ~ scale(Age.months)*scale(TotalSGCounts) + (Season) + (Year) + scale(BCI) + (1|Cohort) + (1|Tattoo.No/Slide) + (1|SocialGroup), data = df_leukocyte_male, family = binomial (link = logit), weights = NeutLymp, control = mi.control2, na.action = "na.fail")

# Overdispersion
od.point(Leukocyte_age_bi1) # 62.66738 so overdispersed

# Add-in observation-level random effect
Leukocyte_age_bi2 <- glmer(cbind(LympFreq, NeutFreq) ~ scale(Age.months)*scale(TotalSGCounts) + (Season) + (Year) + scale(BCI) + (1|Cohort) + (1|Tattoo.No/Slide) + (1|SocialGroup) + (1|Observation), data = df_leukocyte_male, family = binomial (link = logit), weights = NeutLymp, control = mi.control2, na.action = "na.fail")

od.point(Leukocyte_age_bi2) # 0.01945845 - fine


# Males
df_leukocyte_male <- df_leukocyte %>% 
  filter(Sex == "male")

Leukocyte_age_bi1 <- glmer(cbind(LympFreq, NeutFreq) ~ scale(Age.months)*scale(TotalSGCounts) + (Season) + (Year) + scale(BCI) + (1|Cohort) + (1|Tattoo.No/Slide) + (1|SocialGroup) + (1|Observation), data = df_leukocyte_male, family = binomial (link = logit), weights = NeutLymp, control = mi.control2, na.action = "na.fail")

Leukocyte_age_bi2 <- glmer(cbind(LympFreq, NeutFreq) ~ scale(log_Age)*scale(TotalSGCounts) + (Season) + (Year) + scale(BCI) + (1|Cohort) + (1|Tattoo.No/Slide) + (1|SocialGroup) + (1|Observation), data = df_leukocyte_male, family = binomial (link = logit), weights = NeutLymp, control = mi.control2, na.action = "na.fail")

AICc(Leukocyte_age_bi1,Leukocyte_age_bi2)

# Leukocyte_age_bi1, AICc = 75989.74
# Leukocyte_age_bi2, AICc = 75987.44
# Delta AICc = -2.3 (Log_Age)


# Females
df_leukocyte_female <- df_leukocyte %>% 
  filter(Sex == "female")

Leukocyte_age_bi1 <- glmer(cbind(LympFreq, NeutFreq) ~ scale(Age.months)*scale(TotalSGCounts) + (Season) + (Year) + scale(BCI) + (1|Cohort) + (1|Tattoo.No/Slide) + (1|SocialGroup) + (1|Observation), data = df_leukocyte_female, family = binomial (link = logit), weights = NeutLymp, control = mi.control2, na.action = "na.fail")

Leukocyte_age_bi2 <- glmer(cbind(LympFreq, NeutFreq) ~ scale(log_Age)*scale(TotalSGCounts) + (Season) + (Year) + scale(BCI) + (1|Cohort) + (1|Tattoo.No/Slide) + (1|SocialGroup) + (1|Observation), data = df_leukocyte_female, family = binomial (link = logit), weights = NeutLymp, control = mi.control2, na.action = "na.fail")

AICc(Leukocyte_age_bi1,Leukocyte_age_bi2)

# Leukocyte_age_bi1, AICc = 49477.57
# Leukocyte_age_bi2, AICc = 49477.78
# Delta AICc = 0.21 (Age.months)


# Combined dataset (males + females)
Leukocyte_age_bi1 <- glmer(cbind(LympFreq, NeutFreq) ~ scale(Age.months)*(Sex)*scale(TotalSGCounts) + (Season) + (Year) + scale(BCI) + (1|Cohort) + (1|Tattoo.No/Slide) + (1|SocialGroup) + (1|Observation), data = df_leukocyte, family = binomial (link = logit), weights = NeutLymp, control = mi.control2, na.action = "na.fail")

Leukocyte_age_bi2 <- glmer(cbind(LympFreq, NeutFreq) ~ scale(log_Age)*(Sex)*scale(TotalSGCounts) + (Season) + (Year) + scale(BCI) + (1|Cohort) + (1|Tattoo.No/Slide) + (1|SocialGroup) + (1|Observation), data = df_leukocyte, family = binomial (link = logit), weights = NeutLymp, control = mi.control2, na.action = "na.fail")

AICc(Leukocyte_age_bi1,Leukocyte_age_bi2)

# Leukocyte_age_bi1, AICc = 125454.3
# Leukocyte_age_bi2, AICc = 125450.5
# Delta AICc = -3.8 (Log_Age)


# Full dataset and males with log_Age, females with both log_Age and linear age

########################################################################

# Building the models

# Males
df_leukocyte_male <- df_leukocyte %>% 
  filter(Sex == "male")

Leukocyte_age_bi1 <- glmer(cbind(LympFreq, NeutFreq) ~ scale(log_Age)*scale(TotalSGCounts) + (Year) + (Season) + scale(BCI) + (1|Cohort) + (1|Tattoo.No/Slide) + (1|SocialGroup) + (1|Observation), data = df_leukocyte_male, family = binomial (link = logit), weights = NeutLymp, control = mi.control2, na.action = "na.fail")

Leukocyte_age_bi2 <- glmer(cbind(LympFreq, NeutFreq) ~ scale(log_Age) + scale(TotalSGCounts) + (Year) + (Season) + scale(BCI) + (1|Cohort) + (1|Tattoo.No/Slide) + (1|SocialGroup) + (1|Observation), data = df_leukocyte_male, family = binomial (link = logit), weights = NeutLymp, control = mi.control2, na.action = "na.fail")

AICc(Leukocyte_age_bi1, Leukocyte_age_bi2)
# With interaction,     AICc = 75987.44
# Without interaction,  AICc = 75997.23
# Delta AICc = -9.79 (interaction)

# Model should include interaction

Leukocyte_age_bi1 <- glmer(cbind(LympFreq, NeutFreq) ~ scale(log_Age)*scale(TotalSGCounts) + (Year) + (Season) + scale(BCI) + (1|Cohort) + (1|Tattoo.No/Slide) + (1|SocialGroup) + (1|Observation), data = df_leukocyte_male, family = binomial (link = logit), weights = NeutLymp, control = mi.control2, na.action = "na.fail")

summary(Leukocyte_age_bi1)

# Variance inflation factors - collinearity
vif.lme <- function (fit) {
  ## adapted from rms::vif
  v <- vcov(fit)
  nam <- names(fixef(fit))
  ## exclude intercepts
  ns <- sum(1 * (nam == "Intercept" | nam == "(Intercept)"))
  if (ns > 0) {
    v <- v[-(1:ns), -(1:ns), drop = FALSE]
    nam <- nam[-(1:ns)] }
  d <- diag(v)^0.5
  v <- diag(solve(v/(d %o% d)))
  names(v) <- nam
  v }

# Is there any collinearity that needs further investigation >3?
vif.lme(Leukocyte_age_bi1) # No, seems fine

# Bootstrapping - proportions need to be integers for bootstrapping
mcmc.fixed <- bootMer(Leukocyte_age_bi1, FUN=fixef, nsim=5000, type="parametric", seed=1)
coef.mcmc.fixed <- as.data.frame(mcmc.fixed$t)
tabla <- describe(coef.mcmc.fixed)[,c(1:4,11:12)]
colnames(tabla)[4] <- "Std.Error"
tabla$Zeta <- tabla$mean / tabla$Std.Error
tabla$p_boot <- round(2*pnorm(abs(tabla$Zeta), lower.tail=FALSE), 5)
tabla$coeficiente.modelo <- round(fixef(Leukocyte_age_bi1), 5)
print(tabla, digits=5) # Should model selection still be applied?

confint.fixed <- confint.merMod(Leukocyte_age_bi1, parm="beta_", level=0.95, method="boot", boot.type="perc", nsim=5000)
print(confint.fixed, digits=3)

                                    vars    n     mean Std.Error     skew kurtosis      Zeta  p_boot coeficiente.modelo
(Intercept)                            1 5000 -2.32533   0.12737 -0.00782  0.04174 -18.25691 0.00000 -2.32418
scale(log_Age)                         2 5000 -0.21125   0.09535  0.02608  0.00112  -2.21543 0.02673 -0.21315
scale(TotalSGCounts)                   3 5000  0.22029   0.08658 -0.03729  0.04970   2.54425 0.01095 0.21716
Year2018                               4 5000  0.42063   0.13743 -0.04724 -0.03877   3.06077 0.00221 0.42283
SeasonAutumn                           5 5000  0.61720   0.22415  0.00953 -0.05222   2.75346 0.00590 0.61478
SeasonSummer                           6 5000 -0.04583   0.13127  0.03071 -0.02823  -0.34909 0.72703 -0.04850
scale(BCI)                             7 5000 -0.25531   0.09653  0.01982 -0.04433  -2.64494 0.00817 -0.25417
scale(log_Age):scale(TotalSGCounts)    8 5000  0.20152   0.05198 -0.04221  0.19498   3.87705 0.00011 0.20009          

                                              2.5%  97.5%
(Intercept)                                 -2.570 -2.073
scale(log_Age)                              -0.403 -0.015
scale(TotalSGCounts)                         0.050  0.388
Year2018                                     0.148  0.693
SeasonAutumn                                 0.156  1.069
SeasonSummer                                -0.310  0.215
scale(BCI)                                  -0.446 -0.065
scale(log_Age):scale(TotalSGCounts)          0.101  0.304


###

# Females (log age relationship)
df_leukocyte_female <- df_leukocyte %>% 
  filter(Sex == "female")

Leukocyte_age_bi3 <- glmer(cbind(LympFreq, NeutFreq) ~ scale(log_Age)*scale(TotalSGCounts) + (Year) + (Season) + scale(BCI) + (1|Cohort) + (1|Tattoo.No/Slide) + (1|SocialGroup) + (1|Observation), data = df_leukocyte_female, family = binomial (link = logit), weights = NeutLymp, control = mi.control2, na.action = "na.fail")

Leukocyte_age_bi4 <- glmer(cbind(LympFreq, NeutFreq) ~ scale(log_Age) + scale(TotalSGCounts) + (Year) + (Season) + scale(BCI) + (1|Cohort) + (1|Tattoo.No/Slide) + (1|SocialGroup) + (1|Observation), data = df_leukocyte_female, family = binomial (link = logit), weights = NeutLymp, control = mi.control2, na.action = "na.fail")

AICc(Leukocyte_age_bi3,Leukocyte_age_bi4)
# With interaction,     AICc = 49477.78 
# Without interaction,  AICc = 49475.33
# Delta AICc = 2.45

# No clear difference in AICc - need to run with interaction and if the interaction is non-significant then also run without interaction for correct interpretation of first order effects


# With interaction
Leukocyte_age_bi3 <- glmer(cbind(LympFreq, NeutFreq) ~ scale(log_Age)*scale(TotalSGCounts) + (Year) + (Season) + scale(BCI) + (1|Cohort) + (1|Tattoo.No/Slide) + (1|SocialGroup) + (1|Observation), data = df_leukocyte_female, family = binomial (link = logit), weights = NeutLymp, control = mi.control2, na.action = "na.fail")

summary(Leukocyte_age_bi3)

# Variance inflation factors - collinearity
vif.lme <- function (fit) {
  ## adapted from rms::vif
  v <- vcov(fit)
  nam <- names(fixef(fit))
  ## exclude intercepts
  ns <- sum(1 * (nam == "Intercept" | nam == "(Intercept)"))
  if (ns > 0) {
    v <- v[-(1:ns), -(1:ns), drop = FALSE]
    nam <- nam[-(1:ns)] }
  d <- diag(v)^0.5
  v <- diag(solve(v/(d %o% d)))
  names(v) <- nam
  v }

# Is there any collinearity that needs further investigation >3?
vif.lme(Leukocyte_age_bi3) # No, seems fine

# Bootstrapping - proportions need to be integers for bootstrapping
mcmc.fixed <- bootMer(Leukocyte_age_bi3, FUN=fixef, nsim=5000, type="parametric", seed=1)
coef.mcmc.fixed <- as.data.frame(mcmc.fixed$t)
tabla <- describe(coef.mcmc.fixed)[,c(1:4,11:12)]
colnames(tabla)[4] <- "Std.Error"
tabla$Zeta <- tabla$mean / tabla$Std.Error
tabla$p_boot <- round(2*pnorm(abs(tabla$Zeta), lower.tail=FALSE), 5)
tabla$coeficiente.modelo <- round(fixef(Leukocyte_age_bi3), 5)
print(tabla, digits=5) # Should model selection still be applied?

confint.fixed <- confint.merMod(Leukocyte_age_bi3, parm="beta_", level=0.95, method="boot", boot.type="perc", nsim=5000)
print(confint.fixed, digits=3)

                              vars    n      mean    Std.Error    skew     kurtosis     Zeta  p_boot coeficiente.modelo
Intercept                           1 5000 -2.284306   0.18739  0.0070819 -0.042538 -12.190328 0.00000 -2.28593
scale(log_Age)                      2 5000 -0.078125   0.15044 -0.0427910  0.158864  -0.519321 0.60354 -0.07898
scale(TotalSGCounts)                3 5000 -0.107486   0.11494 -0.0881398  0.044674  -0.935149 0.34971 -0.10810
Year2018                            4 5000 -0.016557   0.21119 -0.0067361 -0.065846  -0.078399 0.93751 -0.01201
SeasonAutumn                        5 5000  0.557999   0.31690 -0.0526677 -0.025357   1.760792 0.07827  0.56610
SeasonSummer                        6 5000  0.137248   0.19432  0.0236387  0.029593   0.706314 0.47999  0.13655
scale(BCI)                          7 5000 -0.261783   0.14300  0.0481192  0.086402  -1.830585 0.06716 -0.26207
scale(log_Age):scale(TotalSGCounts) 8 5000 -0.015356   0.11676 -0.0028736 -0.083297  -0.131517 0.89537 -0.01733

                                             2.5%  97.5%
(Intercept)                                 -2.661 -1.911
scale(log_Age)                              -0.386  0.214
scale(TotalSGCounts)                        -0.344  0.122
Year2018                                    -0.447  0.405
SeasonAutumn                                -0.038  1.203
SeasonSummer                                -0.228  0.527
scale(BCI)                                  -0.551  0.015
scale(log_Age):scale(TotalSGCounts)         -0.245  0.210




# Interaction is non-significant so also run without interaction

# Without interaction
Leukocyte_age_bi4 <- glmer(cbind(LympFreq, NeutFreq) ~ scale(log_Age) + scale(TotalSGCounts) + (Year) + (Season) + scale(BCI) + (1|Cohort) + (1|Tattoo.No/Slide) + (1|SocialGroup) + (1|Observation), data = df_leukocyte_female, family = binomial (link = logit), weights = NeutLymp, control = mi.control2, na.action = "na.fail")

summary(Leukocyte_age_bi4)

# Variance inflation factors - collinearity
vif.lme <- function (fit) {
  ## adapted from rms::vif
  v <- vcov(fit)
  nam <- names(fixef(fit))
  ## exclude intercepts
  ns <- sum(1 * (nam == "Intercept" | nam == "(Intercept)"))
  if (ns > 0) {
    v <- v[-(1:ns), -(1:ns), drop = FALSE]
    nam <- nam[-(1:ns)] }
  d <- diag(v)^0.5
  v <- diag(solve(v/(d %o% d)))
  names(v) <- nam
  v }

# Is there any collinearity that needs further investigation >3?
vif.lme(Leukocyte_age_bi4) # No, seems fine

# Bootstrapping - proportions need to be integers for bootstrapping
mcmc.fixed <- bootMer(Leukocyte_age_bi4, FUN=fixef, nsim=5000, type="parametric", seed=1)
coef.mcmc.fixed <- as.data.frame(mcmc.fixed$t)
tabla <- describe(coef.mcmc.fixed)[,c(1:4,11:12)]
colnames(tabla)[4] <- "Std.Error"
tabla$Zeta <- tabla$mean / tabla$Std.Error
tabla$p_boot <- round(2*pnorm(abs(tabla$Zeta), lower.tail=FALSE), 5)
tabla$coeficiente.modelo <- round(fixef(Leukocyte_age_bi4), 5)
print(tabla, digits=5) # Should model selection still be applied?

confint.fixed <- confint.merMod(Leukocyte_age_bi4, parm="beta_", level=0.95, method="boot", boot.type="perc", nsim=5000)
print(confint.fixed, digits=3)

                   vars    n      mean Std.Error       skew   kurtosis      Zeta  p_boot coeficiente.modelo
Intercept             1 5000 -2.276149   0.18283  0.0153469  0.0076092 -12.44931 0.00000           -2.27717
scale(log_Age)        2 5000 -0.076193   0.14925 -0.0999461  0.4734248  -0.51050 0.60970           -0.07609
scale(TotalSGCounts)  3 5000 -0.107098   0.11464 -0.0679788  0.0112094  -0.93421 0.35019           -0.10850
Year2018              4 5000 -0.024804   0.20134  0.0017381 -0.0422264  -0.12320 0.90195           -0.02141
SeasonAutumn          5 5000  0.546626   0.31318 -0.0616163 -0.0031044   1.74541 0.08091            0.55471
SeasonSummer          6 5000  0.138173   0.19336  0.0134218  0.0617624   0.71460 0.47485            0.13795
scale(BCI)            7 5000 -0.258518   0.14355  0.0669927  0.2709186  -1.80087 0.07172           -0.25924

                                              2.5%  97.5%
(Intercept)                                 -2.628 -1.928
scale(log_Age)                              -0.381  0.225
scale(TotalSGCounts)                        -0.350  0.115
Year2018                                    -0.418  0.378
SeasonAutumn                                -0.063  1.170
SeasonSummer                                -0.237  0.520
scale(BCI)                                  -0.542  0.032


###

# Females (linear age relationship)
df_leukocyte_female <- df_leukocyte %>% 
  filter(Sex == "female")

Leukocyte_age_bi5 <- glmer(cbind(LympFreq, NeutFreq) ~ scale(Age.months)*scale(TotalSGCounts) + (Year) + (Season) + scale(BCI) + (1|Cohort) + (1|Tattoo.No/Slide) + (1|SocialGroup) + (1|Observation), data = df_leukocyte_female, family = binomial (link = logit), weights = NeutLymp, control = mi.control2, na.action = "na.fail")

Leukocyte_age_bi6 <- glmer(cbind(LympFreq, NeutFreq) ~ scale(Age.months) + scale(TotalSGCounts) + (Year) + (Season) + scale(BCI) + (1|Cohort) + (1|Tattoo.No/Slide) + (1|SocialGroup) + (1|Observation), data = df_leukocyte_female, family = binomial (link = logit), weights = NeutLymp, control = mi.control2, na.action = "na.fail")

AICc(Leukocyte_age_bi5,Leukocyte_age_bi6)
# With interaction,     AICc = 49477.57
# Without interaction,  AICc = 49475.46
# Delta AICc = 2.11

# No clear difference in AICc - need to run with interaction and if the interaction is non-significant then also run without interaction for correct interpretation of first order effects


# With interaction
Leukocyte_age_bi5 <- glmer(cbind(LympFreq, NeutFreq) ~ scale(Age.months)*scale(TotalSGCounts) + (Year) + (Season) + scale(BCI) + (1|Cohort) + (1|Tattoo.No/Slide) + (1|SocialGroup) + (1|Observation), data = df_leukocyte_female, family = binomial (link = logit), weights = NeutLymp, control = mi.control2, na.action = "na.fail")

summary(Leukocyte_age_bi5)

# Variance inflation factors - collinearity
vif.lme <- function (fit) {
  ## adapted from rms::vif
  v <- vcov(fit)
  nam <- names(fixef(fit))
  ## exclude intercepts
  ns <- sum(1 * (nam == "Intercept" | nam == "(Intercept)"))
  if (ns > 0) {
    v <- v[-(1:ns), -(1:ns), drop = FALSE]
    nam <- nam[-(1:ns)] }
  d <- diag(v)^0.5
  v <- diag(solve(v/(d %o% d)))
  names(v) <- nam
  v }

# Is there any collinearity that needs further investigation >3?
vif.lme(Leukocyte_age_bi5) # No, seems fine

# Bootstrapping - proportions need to be integers for bootstrapping
mcmc.fixed <- bootMer(Leukocyte_age_bi5, FUN=fixef, nsim=5000, type="parametric", seed=1)
coef.mcmc.fixed <- as.data.frame(mcmc.fixed$t)
tabla <- describe(coef.mcmc.fixed)[,c(1:4,11:12)]
colnames(tabla)[4] <- "Std.Error"
tabla$Zeta <- tabla$mean / tabla$Std.Error
tabla$p_boot <- round(2*pnorm(abs(tabla$Zeta), lower.tail=FALSE), 5)
tabla$coeficiente.modelo <- round(fixef(Leukocyte_age_bi5), 5)
print(tabla, digits=5) # Should model selection still be applied?

confint.fixed <- confint.merMod(Leukocyte_age_bi5, parm="beta_", level=0.95, method="boot", boot.type="perc", nsim=5000)
print(confint.fixed, digits=3)


                                     vars  n     mean Std.Error     skew kurtosis      Zeta  p_boot coeficiente.modelo
(Intercept)                             1 5000 -2.26514   0.20078 -0.01213  0.03510 -11.28194 0.00000 -2.26733
scale(Age.months)                       2 5000  0.02802   0.14402 -0.06831  0.05644   0.19457 0.84573 0.02811
scale(TotalSGCounts)                    3 5000 -0.09335   0.11702 -0.07603  0.03635  -0.79769 0.42505 -0.09503
Year2018                                4 5000 -0.09958   0.20398 -0.00982 -0.06659  -0.48820 0.62541 -0.09451
SeasonAutumn                            5 5000  0.49393   0.31631 -0.04255 -0.04107   1.56155 0.11840 0.50343
SeasonSummer                            6 5000  0.16515   0.18762  0.02395  0.04659   0.88023 0.37873 0.16466
scale(BCI)                              7 5000 -0.25884   0.13223 -0.03320  0.14546  -1.95750 0.05029 -0.26142
scale(Age.months):scale(TotalSGCounts)  8 5000  0.06689   0.10329 -0.02342 -0.06800   0.64757 0.51726 0.06488

                                         2.5%  97.5%
(Intercept)                            -2.666 -1.88e+00
scale(Age.months)                      -0.258  3.15e-01
scale(TotalSGCounts)                   -0.323  1.36e-01
Year2018                               -0.505  3.15e-01
SeasonAutumn                           -0.127  1.14e+00
SeasonSummer                           -0.212  5.42e-01
scale(BCI)                             -0.524  3.28e-05
scale(Age.months):scale(TotalSGCounts) -0.138  2.65e-01



# Interaction is non-significant so also run without interaction

# Without interaction
Leukocyte_age_bi6 <- glmer(cbind(LympFreq, NeutFreq) ~ scale(Age.months) + scale(TotalSGCounts) + (Year) + (Season) + scale(BCI) + (1|Cohort) + (1|Tattoo.No/Slide) + (1|SocialGroup) + (1|Observation), data = df_leukocyte_female, family = binomial (link = logit), weights = NeutLymp, control = mi.control2, na.action = "na.fail")

summary(Leukocyte_age_bi6)

# Variance inflation factors - collinearity
vif.lme <- function (fit) {
  ## adapted from rms::vif
  v <- vcov(fit)
  nam <- names(fixef(fit))
  ## exclude intercepts
  ns <- sum(1 * (nam == "Intercept" | nam == "(Intercept)"))
  if (ns > 0) {
    v <- v[-(1:ns), -(1:ns), drop = FALSE]
    nam <- nam[-(1:ns)] }
  d <- diag(v)^0.5
  v <- diag(solve(v/(d %o% d)))
  names(v) <- nam
  v }

# Is there any collinearity that needs further investigation >3?
vif.lme(Leukocyte_age_bi6) # No, seems fine

# Bootstrapping - proportions need to be integers for bootstrapping
mcmc.fixed <- bootMer(Leukocyte_age_bi6, FUN=fixef, nsim=5000, type="parametric", seed=1)
coef.mcmc.fixed <- as.data.frame(mcmc.fixed$t)
tabla <- describe(coef.mcmc.fixed)[,c(1:4,11:12)]
colnames(tabla)[4] <- "Std.Error"
tabla$Zeta <- tabla$mean / tabla$Std.Error
tabla$p_boot <- round(2*pnorm(abs(tabla$Zeta), lower.tail=FALSE), 5)
tabla$coeficiente.modelo <- round(fixef(Leukocyte_age_bi6), 5)
print(tabla, digits=5) # Should model selection still be applied?

confint.fixed <- confint.merMod(Leukocyte_age_bi6, parm="beta_", level=0.95, method="boot", boot.type="perc", nsim=5000)
print(confint.fixed, digits=3)

                     vars  n   mean    Std.Error  skew   kurtosis    Zeta   p_boot     coeficiente.modelo
(Intercept)             1 5000 -2.29340   0.19056 -0.01369  0.03339 -12.03521 0.00000           -2.29498
scale(Age.months)       2 5000  0.01064   0.13278 -0.05789  0.03969   0.08017 0.93610            0.01077
scale(TotalSGCounts)    3 5000 -0.09390   0.11493 -0.06676  0.08837  -0.81703 0.41391           -0.09630
Year2018                4 5000 -0.06115   0.19912 -0.00416 -0.06911  -0.30711 0.75876           -0.05676
SeasonAutumn            5 5000  0.54328   0.31717 -0.04594 -0.05897   1.71289 0.08673            0.55198
SeasonSummer            6 5000  0.15000   0.18970  0.00702  0.07317   0.79072 0.42910            0.14967
scale(BCI)              7 5000 -0.27903   0.12896 -0.02357  0.15150  -2.16375 0.03048           -0.28097

                      2.5%    97.5%
(Intercept)          -2.6698 -1.927
scale(Age.months)    -0.2521  0.273
scale(TotalSGCounts) -0.3210  0.138
Year2018             -0.4532  0.338
SeasonAutumn         -0.0687  1.198
SeasonSummer         -0.2277  0.530
scale(BCI)           -0.5380 -0.034




# Full dataset
Leukocyte_age_bi7 <- glmer(cbind(LympFreq, NeutFreq) ~ scale(log_Age)*(Sex)*scale(TotalSGCounts) + (Year) + (Season) + scale(BCI) + (1|Cohort) + (1|Tattoo.No/Slide) + (1|SocialGroup) + (1|Observation), data = df_leukocyte, family = binomial (link = logit), weights = NeutLymp, control = mi.control2, na.action = "na.fail")

Leukocyte_age_bi8 <- glmer(cbind(LympFreq, NeutFreq) ~ scale(log_Age)*(Sex) + scale(log_Age):scale(TotalSGCounts) + (Sex):scale(TotalSGCounts) + (Year) + (Season) + scale(BCI) + (1|Cohort) + (1|Tattoo.No/Slide) + (1|SocialGroup) + (1|Observation), data = df_leukocyte, family = binomial (link = logit), weights = NeutLymp, control = mi.control2, na.action = "na.fail")

AICc(Leukocyte_age_bi7,Leukocyte_age_bi8)
# With interaction,     AICc = 125450.5
# Without interaction,  AICc = 125453.3
# Delta AICc = -2.8

# No clear difference in AICc - need to run with interaction and if the interaction is non-significant then also run without interaction for correct interpretation of first order effects

# With interaction
Leukocyte_age_bi7 <- glmer(cbind(LympFreq, NeutFreq) ~ scale(log_Age)*(Sex)*scale(TotalSGCounts) + (Year) + (Season) + scale(BCI) + (1|Cohort) + (1|Tattoo.No/Slide) + (1|SocialGroup) + (1|Observation), data = df_leukocyte, family = binomial (link = logit), weights = NeutLymp, control = mi.control2, na.action = "na.fail")

summary(Leukocyte_age_bi7)

# Variance inflation factors - collinearity
vif.lme <- function (fit) {
  ## adapted from rms::vif
  v <- vcov(fit)
  nam <- names(fixef(fit))
  ## exclude intercepts
  ns <- sum(1 * (nam == "Intercept" | nam == "(Intercept)"))
  if (ns > 0) {
    v <- v[-(1:ns), -(1:ns), drop = FALSE]
    nam <- nam[-(1:ns)] }
  d <- diag(v)^0.5
  v <- diag(solve(v/(d %o% d)))
  names(v) <- nam
  v }

# Is there any collinearity that needs further investigation >3?
vif.lme(Leukocyte_age_bi7) # No, seems fine

# Bootstrapping - proportions need to be integers for bootstrapping
mcmc.fixed <- bootMer(Leukocyte_age_bi7, FUN=fixef, nsim=5000, type="parametric", seed=1)
coef.mcmc.fixed <- as.data.frame(mcmc.fixed$t)
tabla <- describe(coef.mcmc.fixed)[,c(1:4,11:12)]
colnames(tabla)[4] <- "Std.Error"
tabla$Zeta <- tabla$mean / tabla$Std.Error
tabla$p_boot <- round(2*pnorm(abs(tabla$Zeta), lower.tail=FALSE), 5)
tabla$coeficiente.modelo <- round(fixef(Leukocyte_age_bi7), 5)
print(tabla, digits=5) # Should model selection still be applied?

confint.fixed <- confint.merMod(Leukocyte_age_bi7, parm="beta_", level=0.95, method="boot", boot.type="perc", nsim=5000)
print(confint.fixed, digits=3)


                                      vars    n      mean     Std.Error    skew     kurtosis    Zeta  p_boot coefmodelo
Intercept                                   1 5000 -2.360617  0.121696 -0.0221184 -0.0636177 -19.39764 0.00000 -2.36070
scale(log_Age)                              2 5000 -0.108109  0.103627 -0.0202086 -0.1134495  -1.04325 0.29683 -0.10834
Sexmale                                     3 5000  0.115352  0.120799 -0.0090671 -0.0625588   0.95491 0.33962  0.11549
scale(TotalSGCounts)                        4 5000 -0.151858  0.099002 -0.0434787  0.0054308  -1.53389 0.12506 -0.15202
Year2018                                    5 5000  0.258415  0.119480 -0.0355190  0.0152346   2.16284 0.03055  0.25907
SeasonAutumn                                6 5000  0.627877  0.196111  0.0033444  0.0100754   3.20164 0.00137  0.62688
SeasonSummer                                7 5000  0.045042  0.116352 -0.0245796  0.0049887   0.38712 0.69867  0.04428
scale(BCI)                                  8 5000 -0.275193  0.081920  0.0205003  0.0741400  -3.35928 0.00078 -0.27513
scale(log_Age):Sexmale                      9 5000 -0.059628  0.118272 -0.0426960 -0.0286211  -0.50416 0.61415 -0.05935
scale(log_Age):scale(TotalSGCounts)         10 5000 -0.096482  0.105719 -0.0035178  0.0438733 -0.91263 0.36144 -0.09414
Sexmale:scale(TotalSGCounts)                11 5000  0.392163  0.123893 -0.0221029 -0.1105974 3.16533 0.00155  0.39053
scale(log_Age):Sexmale:scale(TotalSGCounts) 12 5000  0.294689  0.117871  0.0750681  0.1706854 2.50011 0.01242  0.29095

                                             2.5%   97.5%
(Intercept)                                 -2.593 -2.125
scale(log_Age)                              -0.313  0.098
Sexmale                                     -0.124  0.349
scale(TotalSGCounts)                        -0.344  0.042
Year2018                                    -0.108  5.819
SeasonAutumn                                 0.251  0.995
SeasonSummer                                -0.186  0.278
scale(BCI)                                  -0.432 -0.114
scale(log_Age):Sexmale                      -0.293  0.172
scale(log_Age):scale(TotalSGCounts)         -0.302  0.115
Sexmale:scale(TotalSGCounts)                 0.146  0.637
scale(log_Age):Sexmale:scale(TotalSGCounts)  0.060  0.533


# Interaction is significant so no need to run the models without the ineraction


##########################################################

# Figure for males
df_leukocyte <- df_leukocyte %>% 
  filter(Sex == "male")

Leukocyte_age <- glmer(cbind(LympFreq, NeutFreq) ~ scale(log_Age)*scale(TotalSGCounts) + (Year) + (Season) + scale(BCI) + (1|Cohort) + (1|Tattoo.No/Slide) + (1|SocialGroup) + (1|Observation), data = df_leukocyte, family = binomial (link = logit), weights = NeutLymp, control = mi.control2, na.action = "na.fail")

ss <- getME(Leukocyte_age,c("theta","fixef"))
mod_glm2h <- update(Leukocyte_age,start=ss,control=glmerControl(optCtrl=list(maxfun=2e4)))

new.data<-as.data.frame(unique(cbind(df_leukocyte$log_Age, df_leukocyte$TotalSGCounts, df_leukocyte$Year, df_leukocyte$Season, df_leukocyte$BCI, df_leukocyte$Cohort, df_leukocyte$Tattoo.No, df_leukocyte$Slide, df_leukocyte$SocialGroup, df_leukocyte$Observation)))
colnames(new.data) <- c("log_Age","TotalSGCounts","Year","Season","BCI","Cohort","Tattoo.No","Slide","SocialGroup","Observation")
#df1 <- c(11.1514,2.479892,7,6.600414,1,3,16,20,11,143)
#new.data <- rbind(df1,new.data)
str(new.data)

Predictions2=predict(Leukocyte_age, re.form=NA, type="response")

pred.l2<-cbind(new.data, Predictions2) 

median(pred.l2$TotalSGCounts) # 10
mean(pred.l2$TotalSGCounts) # 9.058282

pred.l2 <- pred.l2 %>% 
  mutate(Size.group = ifelse(TotalSGCounts <= 9.058282, "Small group size", "Large group size"))
pred.l2$Size.group <- as.factor(as.character(pred.l2$Size.group))

df_leukocyte <- df_leukocyte %>% 
  filter(Sex == "male") %>% 
  mutate(Size.group = ifelse(TotalSGCounts <= 9.058282, "Small group size", "Large group size"))
df_leukocyte$Size.group <- as.factor(as.character(df_leukocyte$Size.group))

# Log graph
df_leukocyte <- df_leukocyte %>% 
  mutate(Age_back = (10^log_Age)) %>% 
  mutate(Age_back_year = Age_back/12) 

pred.l2 <- pred.l2 %>% 
  mutate(Age_back = (10^log_Age)) %>% 
  mutate(Age_back_year = Age_back/12)

AA <- ggplot(df_leukocyte, aes(x = Age_back_year, y = LtoNProp, color = Size.group)) +
  geom_jitter(aes(shape = Size.group),width = 0.15, height = 0.03, size = 3) +
  geom_smooth(data = pred.l2, aes(x= Age_back_year, y= Predictions2, group = Size.group, color = Size.group, linetype = Size.group), method = "lm", formula = y~log(x), fullrange = TRUE, size = 1.5) +
  scale_y_continuous(limits = c(0.00,0.50), breaks = c(0.00,0.05,0.10,0.15,0.20,0.25,0.30,0.35,0.40,0.45,0.50)) +
  scale_x_continuous(limits = c(-0.001, 14.2), breaks = c(0.00,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14)) +
  scale_color_manual(values = c("#0072B2", "#D55E00")) +
  labs(x=expression("Age (years)"), y="Proportion of lymphocytes out of \n neutrophils and lymphocytes") + 
  geom_text(x=1.00, y=0.50, label = "Males", col="black", size = 12, fontface = "italic") +
  theme_classic() + #scale_y_continuous(expand = c(0,0)) + 
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), axis.line = element_line(colour = 'black', size = 1), axis.text.x = element_text(colour = 'black', margin = margin(t = 5, r = 0, b = 0, l = 0)), axis.text.y = element_text(colour = 'black', margin = margin(t = 0, r = 5, b = 0, l = 0)), axis.ticks.x = element_line(size = 1, colour = 'black'), axis.ticks.length=unit(0.2,"cm"), axis.ticks.y = element_line(size = 1, colour = 'black'), text = element_text(size = 38), legend.title=element_blank(), legend.text=element_text(size=40), legend.key.size = unit(3.5, 'lines'), legend.position = c(0.77, 0.90), axis.title.y = element_text(size = 50, margin = margin(t = 0, r = 50, b = 0, l = 0)), axis.title.x = element_text(size = 50, margin = margin(t = 50, r = 0, b = 15, l = 0))) + guides(color=guide_legend(override.aes=list(fill=NA)))# plot.title = element_text(hjust = 0.5)

plot_grid(AA, align = "v", nrow = 1)
ggsave("Figure leukocyte log19 600 dpi.pdf", width = 18, height = 15, dpi = 600)


# Effect sizes based on predicted values
pred.l3 <- pred.l2 %>% 
  filter(TotalSGCounts <= 9.058282)

# Predictions for young individuals in smaller groups: 0.28925932
# Predictions for old individuals in smaller groups: 0.05836574
# So change with age in smaller groups is 0.05836574/0.28925932*100 = 80%

pred.l4 <- pred.l2 %>% 
  filter(TotalSGCounts > 9.058282)

# Predictions for young individuals in larger groups: 0.17250273
# Predictions for old individuals in larger groups: 0.08649972
# So change with age in smaller groups is 0.08649972/0.17250273*100 = 50%

