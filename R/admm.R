#' @export
admm <- function(S, Theta_back, lambda, rho, max_iter = 1000, e_abs = 10^-4, e_rel = 10^-2) {
  p <- nrow(S)
  Theta <- matrix(0, nrow = p, ncol = p)
  Z <- Z_old <- matrix(0, nrow = p, ncol = p)
  U <- matrix(0, nrow = p, ncol = p)

  for (i in seq_len(max_iter)) {
    Theta <- update_Theta(S, Z, U, rho)
    Z <- update_Z(Theta, U, Theta_back, lambda, rho)
    U <- update_U(Theta, Z, U)
    if (is_conversed(Theta, Z, U, Z_old, rho, p, e_abs, e_rel)) {
      break
    }
    Z_old <- Z
  }
  if (i == max_iter) warning("rearch max iteration")

  Theta
}

update_Theta <- function(S, Z, U, rho) {
  p <- nrow(S)
  E <- eigen(rho * (Z - U) - S)
  Q <- E$vectors
  lambda <- E$values
  Theta_tilde <- matrix(0, nrow = p, ncol = p)
  diag(Theta_tilde) <- (lambda + sqrt(lambda^2 + 4 * rho)) / (2 * rho)
  Theta <- Q %*% Theta_tilde %*% t(Q)
  Theta
}

update_Z <- function(Theta, U, Theta_back, lambda, rho) {
  soft_thresh_func <- generate_soft_thresh_func(lambda / rho)
  Z <- soft_thresh_func(Theta + U - Theta_back)
  Z
}

generate_soft_thresh_func <- function(lambda) {
  function(x) {
    ifelse(x >= lambda, x - lambda,
           ifelse(x <= -lambda, x + lambda, 0))
  }
}

update_U <- function(Theta, Z, U) {
  U <- Theta - Z + U
  U
}

is_conversed <- function(Theta, Z, U, Z_old, rho, n, e_abs, e_rel) {
  e_primal <- n * e_abs + e_rel * max(Frobenius_norm(Theta) , Frobenius_norm(Z))
  e_dual <- n * e_abs + e_rel * Frobenius_norm(rho * U)
  Frobenius_norm(Theta - Z) <= e_primal && Frobenius_norm(Z - Z_old) <= e_dual
}

Frobenius_norm <- function(X_matrix) {
  sqrt(sum(X_matrix ^ 2))
}