# pipeline variables
# $Y an n vector of outcomes (training data)
# $X an n by p matrix of covariates (training data)
# $Ytest an n vector of outcomes in test data
# $Xtest an n by p matrix of covariates in test data
# $beta_est an n vector of estimated values beta (learned from training data)
# $error a scalar measure of accuracy

# module groups
#
# simulate: -> $X, $Y, $Xtest, $Ytest
# analyze: $Y, $X -> $beta_est
# score: $beta_est, $Xtest, $Ytest -> $error


en_sim : simulate.R + R(d = en_sim(scenario))
  scenario: eg1, eg2, eg3, eg4
  $Y: d$Y
  $X: d$X
  $Ytest: d$Ytest
  $Xtest: d$Xtest

sparse: simulate.R + R(d=simple_sim_regression(n,p,pve,pi0))
  scenario: sparse
  n: 100
  p: 100
  pve: 0.5
  pi0: 0.9
  $Y: d$Y
  $X: d$X
  $Ytest: d$Ytest
  $Xtest: d$Xtest

dense(sparse):
  scenario: dense
  pi0: 0

lasso : glmnet_fit.R
  alpha: 1
  X: $X
  Y: $Y
  $beta_est: bhat

ridge : glmnet_fit.R
  alpha: 0
  X: $X
  Y: $Y
  $beta_est: bhat

en : glmnet_fit.R
    alpha: 0.5
    X: $X
    Y: $Y
    $beta_est: bhat

varbvs: R(fit=varbvs::varbvs(X,Z=NULL,y=Y))
  X: $X
  Y: $Y
  $beta_est: fit$beta

susie: R(fit=susieR::susie(X,Y=Y,L=L); bhat = susieR:::coef.susie(fit))
    L: 10
    X: $X
    Y: $Y
    $beta_est: bhat

susie2: R(fit=susieR::susie(X,Y=Y,L=L); bhat = susieR:::coef.susie(fit))
    L: 20
    X: $X
    Y: $Y
    $beta_est: bhat

sq_err : R(mse = mean( (X %*% b - Y)^2))
  b: $beta_est
  Y: $Ytest
  X: $Xtest
  $error: mse

DSC:
  define:
     simulate: en_sim, sparse, dense
     analyze: lasso, ridge, en #, susie, susie2, varbvs
     score: sq_err
  run: simulate * analyze * score
  exec_path: code
  output: dsc_result
