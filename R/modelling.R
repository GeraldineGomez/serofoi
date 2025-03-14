  # TODO Complete @param documentation


#' Function that runs the specified stan model for the Force-of-Infection and estimates de seroprevalence based on the result of the fit
#'
#' This function runs the specified model for the Force-of-Infection \code{foi_model} using the data froma seroprevalence survey
#' \code{serodata} as the input data. See \link{fit_seromodel} for further details.
#'
#' @param serodata A data frame containing the data from a seroprevalence survey.
#' This data frame must contain the following columns:
#' \tabular{ll}{
#' \code{survey} \tab survey Label of the current survey \cr \tab \cr
#' \code{total} \tab Number of samples for each age group\cr \tab \cr
#' \code{counts} \tab Number of positive samples for each age group\cr \tab \cr
#' \code{age_min} \tab age_min \cr \tab \cr
#' \code{age_max} \tab age_max \cr \tab \cr
#' \code{tsur} \tab Year in which the survey took place \cr \tab \cr
#' \code{country} \tab The country where the survey took place \cr \tab \cr
#' \code{test} \tab The type of test taken \cr \tab \cr
#' \code{antibody} \tab antibody \cr \tab \cr
#' \code{age_mean_f} \tab Floor value of the average between age_min and age_max \cr \tab \cr
#' \code{sample_size} \tab The size of the sample \cr \tab \cr
#' \code{birth_year} \tab The year in which the individuals of each age group were bornt \cr \tab \cr
#' \code{prev_obs} \tab Observed prevalence \cr \tab \cr
#' \code{prev_obs_lower} \tab Lower limit of the confidence interval for the observed prevalence \cr \tab \cr
#' \code{prev_obs_upper} \tab Upper limit of the confidence interval for the observed prevalence \cr \tab \cr
#' }
#' The last six colums can be added to \code{serodata} by means of the function \code{\link{prepare_serodata}}.
#' @param foi_model Name of the selected model. Current version provides three options:
#' \describe{
#' \item{\code{"constant"}}{Runs a constant model}
#' \item{\code{"tv_normal"}}{Runs a normal model}
#' \item{\code{"tv_normal_log"}}{Runs a normal logarithmic model}
#' }
#' @param n_iters Number of interations for eah chain including the warmup. \code{iter} in \link[rstan]{sampling}.
#' @param n_thin Positive integer specifying the period for saving samples. \code{thin} in \link[rstan]{sampling}.
#' @param delta Real number between 0 and 1 that represents the target average acceptance probability.
#' Increasing the value of \code{delta} will result in a smaller step size and fewer divergences.
#' For further details refer to the \code{control} parameter in \link[rstan]{sampling} or \href{https://mc-stan.org/rstanarm/reference/adapt_delta.html}{here}.
#' @param m_treed Maximum tree depth for the binary tree used in the NUTS stan sampler. For further details refer to the \code{control} parameter in \link[rstan]{sampling}.
#' @param decades Number of decades covered by the survey data.
#' @param print_summary TBD
#' @return \code{seromodel_object}. An object containing relevant information about the implementation of the model. For further details refer to \link{fit_seromodel}.
#' @examples
#' \dontrun{
#' serodata <- prepare_serodata(serodata)
#' run_seromodel (serodata,
#'            foi_model = "constant")
#' }
#' @export
run_seromodel <- function(serodata,
                          foi_model = "constant",
                          n_iters = 1000,
                          n_thin = 2,
                          delta = 0.90,
                          m_treed = 10,
                          decades = 0,
                          print_summary = TRUE) {
  survey <- unique(serodata$survey)
  if (length(survey) > 1) warning("You have more than 1 surveys or survey codes")
  seromodel_object <- fit_seromodel(serodata = serodata,
                                    foi_model = foi_model,
                                    n_iters = n_iters,
                                    n_thin = n_thin,
                                    delta = delta,
                                    m_treed = m_treed,
                                    decades = decades); print(paste0("serofoi model ",
                                                                      foi_model,
                                                                      " finished running ------"))
  if (print_summary){
    print(t(seromodel_object$model_summary))
  }
  return(seromodel_object)
}

#' Function that fits the selected model to the specified seroprevalence survey data
#'
#' This function fits the specified model \code{foi_model} to the serological survey data \code{serodata}
#' by means of the \link[rstan]{sampling} method. The function determines whether the corresponding stan model
#' object needs to be compiled by rstan.
#' @param serodata A data frame containing the data from a seroprevalence survey. For further details refer to \link{run_seromodel}.
#' @param foi_model Name of the selected model. Current version provides three options:
#' \describe{
#' \item{\code{"constant"}}{Runs a constant model}
#' \item{\code{"tv_normal"}}{Runs a normal model}
#' \item{\code{"tv_normal_log"}}{Runs a normal logarithmic model}
#' }
#' @param n_iters Number of interations for eah chain including the warmup. \code{iter} in \link[rstan]{sampling}.
#' @param n_thin Positive integer specifying the period for saving samples. \code{thin} in \link[rstan]{sampling}.
#' @param delta Real number between 0 and 1 that represents the target average acceptance probability.
#' Increasing the value of \code{delta} will result in a smaller step size and fewer divergences.
#' For further details refer to the \code{control} parameter in \link[rstan]{sampling} or \href{https://mc-stan.org/rstanarm/reference/adapt_delta.html}{here}.
#' @param m_treed Maximum tree depth for the binary tree used in the NUTS stan sampler. For further details refer to the \code{control} parameter in \link[rstan]{sampling}.
#' @param decades Number of decades covered by the survey data.
#' @return \code{seromodel_object}. An object containing relevant information about the implementation of the model. It contains the following:
#' \tabular{ll}{
#' \code{fit} \tab \code{stanfit} object returned by the function \link[rstan]{sampling} \cr \tab \cr
#' \code{serodata} \tab A data frame containing the data from a seroprevalence survey. For further details refer to \link{run_seromodel}.\cr \tab \cr
#' \code{stan_data} \tab List containing \code{Nobs}, \code{Npos}, \code{Ntotal}, \code{Age}, \code{Ymax}, \code{AgeExpoMatrix} and \code{NDecades}.
#' This object is used as an input for the \link[rstan]{sampling} function \cr \tab \cr
#' \code{exposure_years} \tab Integer atomic vector containing the actual exposure years (1946, ..., 2007 e.g.) \cr \tab \cr
#' \code{exposure_ages} \tab Integer atomic vector containing the numeration of the exposure ages. \cr \tab \cr
#' \code{n_iters} \tab Number of interations for eah chain including the warmup. \cr \tab \cr
#' \code{n_thin} \tab Positive integer specifying the period for saving samples. \cr \tab \cr
#' \code{n_warmup} \tab Number of warm up iterations. Set by default as n_iters/2. \cr \tab \cr
#' \code{foi_model} \tab The name of the model\cr \tab \cr
#' \code{delta} \tab Real number between 0 and 1 that represents the target average acceptance probability. \cr \tab \cr
#' \code{m_treed} \tab Maximum tree depth for the binary tree used in the NUTS stan sampler. \cr \tab \cr
#' \code{loo_fit} \tab Efficient approximate leave-one-out cross-validation. Refer to \link[loo]{loo} for further details. \cr \tab \cr
#' \code{foi_cent_est} \tab A data fram e containing \code{year} (corresponding to \code{exposure_years}), \code{lower}, \code{upper}, and \code{medianv} \cr \tab \cr
#' \code{foi_post_s} \tab Sample n rows from a table. Refer to \link[dplyr]{sample_n} for further details. \cr \tab \cr
#' \code{model_summary} \tab A data fram containing the summary of the model. Refer to \link{extract_seromodel_summary} for further details. \cr \tab \cr
#' }

#' @examples
#' \dontrun{
#' data("serodata")
#' serodata <- prepare_serodata(serodata)
#' seromodel_fit <- fit_seromodel(serodata = serodata,
#'                                foi_model = "constant")
#' }
#'
#' @export
fit_seromodel <- function(serodata,
                          foi_model,
                          n_iters = 1000,
                          n_thin = 2,
                          delta = 0.90,
                          m_treed = 10,
                          decades = 0) {
  # TODO Add a warning because there are exceptions where a minimal amount of iterations is needed
  model <- stanmodels[[foi_model]]
  exposure_ages <- get_exposure_ages(serodata)
  exposure_years <- (min(serodata$birth_year):serodata$tsur[1])[-1]
  exposure_matrix <- get_exposure_matrix(serodata)
  Nobs <- nrow(serodata)

  stan_data <- list(
    Nobs = Nobs,
    Npos = serodata$counts,
    Ntotal = serodata$total,
    Age = serodata$age_mean_f,
    Ymax = max(exposure_ages),
    AgeExpoMatrix = exposure_matrix,
    NDecades = decades
  )

  n_warmup <- floor(n_iters / 2)

  if (foi_model == "tv_normal_log") {
    f_init <- function() {
      list(log_foi = rep(-3, length(exposure_ages)))
    }
    lower_quantile = 0.1
    upper_quantile = 0.9
    medianv_quantile = 0.5
  }

  else {
  f_init <- function() {
    list(foi = rep(0.01, length(exposure_ages)))
  }
    lower_quantile = 0.05
    upper_quantile = 0.95
    medianv_quantile = 0.5

  }

  fit <- rstan::sampling(
    model,
    data = stan_data,
    iter = n_iters,
    chains = 4,
    init = f_init,
    warmup = n_warmup,
    verbose = FALSE,
    refresh = 0,
    control = list(adapt_delta = delta,
                   max_treedepth = m_treed),
    seed = "12345",
    thin = n_thin,
    chain_id = 0 # https://github.com/stan-dev/rstan/issues/761#issuecomment-647029649
  )

  if (class(fit@sim$samples) != "NULL") {
    loo_fit <- loo::loo(fit, save_psis = TRUE, "logLikelihood")
    foi <- rstan::extract(fit, "foi", inc_warmup = FALSE)[[1]]
    # foi <- rstan::extract(fit, "foi", inc_warmup = TRUE, permuted=FALSE)[[1]]
    # generates central estimations
    foi_cent_est <- data.frame(
      year = exposure_years,
      lower = apply(foi, 2, function(x) quantile(x, lower_quantile)),

      upper = apply(foi, 2, function(x) quantile(x, upper_quantile)),

      medianv = apply(foi, 2, function(x) quantile(x, medianv_quantile))
    )


    # generates a sample of iterations
    if (n_iters >= 2000) {
      foi_post_s <- dplyr::sample_n(as.data.frame(foi), size = 1000)
      colnames(foi_post_s) <- exposure_years
    } else {
      foi_post_s <- as.data.frame(foi)
      colnames(foi_post_s) <- exposure_years
    }

    seromodel_object <- list(
      fit = fit,
      serodata = serodata,
      stan_data = stan_data,
      exposure_years = exposure_years,
      exposure_ages = exposure_ages,
      n_iters = n_iters,
      n_thin = n_thin,
      n_warmup = n_warmup,
      foi_model = foi_model,
      delta = delta,
      m_treed = m_treed,
      loo_fit = loo_fit,
      foi_cent_est = foi_cent_est,
      foi_post_s = foi_post_s
    )
    seromodel_object$model_summary <-
      extract_seromodel_summary(seromodel_object)
  } else {
    loo_fit <- c(-1e10, 0)
    seromodel_object <- list(
      fit = "no model",
      serodata = serodata,
      stan_data = stan_data,
      exposure_years = exposure_years,
      exposure_ages = exposure_ages,
      n_iters = n_iters,
      n_thin = n_thin,
      n_warmup = n_warmup,
      model = foi_model,
      delta = delta,
      m_treed = m_treed,
      loo_fit = loo_fit,
      model_summary = NA
    )
  }

  return(seromodel_object)
}


#' Function that generates an atomic vector containing the corresponding exposition years of a serological survey
#'
#' This function generates an atomic vector containing the exposition years corresponding to the specified serological survey data \code{serodata}.
#' The exposition years to the disease for each individual corresponds to the time from birth to the moment of the survey.
#' @param serodata A data frame containing the data from a seroprevalence survey. This data frame must contain the year of birth for each individual (birth_year) and the time of the survey (tsur). birth_year can be constructed by means of the \link{prepare_serodata} function.
#' @return \code{exposure_ages}. An atomic vector with the numeration of the exposition years in serodata
#' @examples
#' \dontrun{
#' data("serodata")
#' serodata <- prepare_serodata(serodata = serodata, alpha = 0.05)
#' exposure_ages <- get_exposure_ages(serodata)
#' }
#' @export
get_exposure_ages <- function(serodata) {
  return(seq_along(min(serodata$birth_year):(serodata$tsur[1] - 1)))
}

# TODO Is necessary to explain better what we mean by the exposure matrix.
#' Function that generates the exposure matrix corresponding to a serological survey
#'
#' @param serodata A data frame containing the data from a seroprevalence survey. This data frame must contain the year of birth for each individual (birth_year) and the time of the survey (tsur). birth_year can be constructed by means of the \link{prepare_serodata} function.
#' @return \code{exposure_output}. An atomic matrix containing the expositions for each entry of \code{serodata} by year.
#' @examples
#' \dontrun{
#' data("serodata")
#' serodata <- prepare_serodata(serodata = serodata)
#' exposure_matrix <- get_exposure_matrix(serodata = serodata)
#' }
#' @export
get_exposure_matrix <- function(serodata) {
  age_class <- serodata$age_mean_f
  exposure_ages <- get_exposure_ages(serodata)
  ly <- length(exposure_ages)
  exposure <- matrix(0, nrow = length(age_class), ncol = ly)
  for (k in 1:length(age_class))
    exposure[k, (ly - age_class[k] + 1):ly] <- 1
  exposure_output <- exposure
  return(exposure_output)
}


#' Method to extact a summary of the specified serological model object
#'
#' This method extracts a summary corresponding to a serological model object that contains information about the original serological
#' survey data used to fit the model, such as the year when the survey took place, the type of test taken and the corresponding antibody,
#' as well as information about the convergence of the model, like the expected log pointwise predictive density \code{elpd} and its
#' corresponding standar deviation.
#' @param seromodel_object \code{seromodel_object}. An object containing relevant information about the implementation of the model.
#' Refer to \link{fit_seromodel} for further details.
#' @return \code{model_summary}. Object with a summary of \code{seromodel_object} containing the following:
#' \tabular{ll}{
#' \code{foi_model} \tab Name of the selected model. \cr \tab \cr
#' \code{data_set} \tab Seroprevalence survey label.\cr \tab \cr
#' \code{country} \tab Name of the country were the survey was conducted in. \cr \tab \cr
#' \code{year} \tab Year in which the survey was conducted. \cr \tab \cr
#' \code{test} \tab Type of test of the survey. \cr \tab \cr
#' \code{antibody} \tab Antibody \cr \tab \cr
#' \code{n_sample} \tab Total number of samples in the survey. \cr \tab \cr
#' \code{n_agec} \tab Number of age groups considered. \cr \tab \cr
#' \code{n_iter} \tab Number of interations for eah chain including the warmup. \cr \tab \cr
#' \code{elpd} \tab elpd \cr \tab \cr
#' \code{se} \tab se \cr \tab \cr
#' \code{converged} \tab convergence \cr \tab \cr
#' }
#' @examples
#' \dontrun{
#' data("serodata")
#' serodata <- prepare_serodata(serodata)
#' seromodel_object <- run_seromodel(serodata = serodata,
#'                                   foi_model = "constant")
#' extract_seromodel_summary(seromodel_object)
#' }
#' @export
extract_seromodel_summary <- function(seromodel_object) {
  foi_model <- seromodel_object$foi_model
  serodata <- seromodel_object$serodata
  #------- Loo estimates

  loo_fit <- seromodel_object$loo_fit
  if (sum(is.na(loo_fit)) < 1) {
    lll <- as.numeric((round(loo_fit$estimates[1, ], 2)))
  } else {
    lll <- c(-1e10, 0)
  }
  model_summary <- data.frame(
    foi_model = foi_model,
    dataset = serodata$survey[1],
    country = serodata$country[1],
    year = serodata$tsur[1],
    test = serodata$test[1],
    antibody = serodata$antibody[1],
    n_sample = sum(serodata$total),
    n_agec = length(serodata$age_mean_f),
    n_iter = seromodel_object$n_iters,
    elpd = lll[1],
    se = lll[2],
    converged = NA
  )

  rhats <- get_table_rhats(seromodel_object)
  if (any(rhats$rhat > 1.1) == FALSE) {
    model_summary$converged <- "Yes"
  }

  return(model_summary)
}

# TODO Complete @param documentation
#' Function that generates an object containing the confidence interval based on a
#' Force-of-Infection fitting
#'
#' This function computes the corresponding binomial confidence intervals for the obtained prevalence based on a fitting
#' of the Force-of-Infection \code{foi} for plotting an analysis purposes.
#' @param foi Object containing the information of the force of infection. It is obtained from \code{rstan::extract(seromodel_object$fit, "foi", inc_warmup = FALSE)[[1]]}.
#' @param serodata A data frame containing the data from a seroprevalence survey. For further details refer to \link{run_seromodel}.
#' @param bin_data TBD
#' @return \code{prev_final}. The expanded prevalence data. This is used for plotting purposes in the \code{visualization} module.
#' @examples
#' \dontrun{
#' serodata <- prepare_serodata(serodata)
#' seromodel_object <- run_seromodel(serodata = serodata,
#'                           foi_model = "constant")
#' foi <- rstan::extract(seromodel_object$fit, "foi")[[1]]
#' get_prev_expanded <- function(foi, serodata)
#' }
#' @export
get_prev_expanded <- function(foi,
                              serodata,
                              bin_data = FALSE) {
  dim_foi <- dim(foi)[2]
  # TODO: check whether this conditional is necessary
  if (dim_foi < 80) {
    oldest_year <- 80 - dim_foi + 1
    foin <- matrix(NA, nrow = dim(foi)[1], 80)
    foin[, oldest_year:80] <- foi
    foin[, 1:(oldest_year - 1)] <- rowMeans(foi[, 1:5])
  } else {
    foin <- foi
  }

  foi_expanded <- foin

  age_class <- 1:NCOL(foi_expanded)
  ly <- NCOL(foi_expanded)
  exposure <- matrix(0, nrow = length(age_class), ncol = ly)
  for (k in 1:length(age_class))
    exposure[k, (ly - age_class[k] + 1):ly] <- 1
  exposure_expanded <- exposure

  iterf <- NROW(foi_expanded)
  age_max <- NROW(exposure_expanded)
  prev_pn <- matrix(NA, nrow = iterf, ncol = age_max)
  for (i in 1:iterf) {
    prev_pn[i, ] <- 1 - exp(-exposure_expanded %*% foi_expanded[i, ])
  }

  lower <- apply(prev_pn, 2, function(x) quantile(x, 0.1))

  upper <- apply(prev_pn, 2, function(x) quantile(x, 0.9))

  medianv <- apply(prev_pn, 2, function(x) quantile(x, 0.5))

  predicted_prev <- data.frame(
    age = 1:age_max,
    predicted_prev = medianv,
    predicted_prev_lower = lower,
    predicted_prev_upper = upper
  )

  observed_prev <- serodata %>%
    dplyr::select(age_mean_f,
                  prev_obs,
                  prev_obs_lower,
                  prev_obs_upper,
                  total,
                  counts) %>%
    dplyr::rename(age = age_mean_f,
                  sample_by_age = total,
                  positives = counts)

  prev_expanded <-
    base::merge(predicted_prev,
                observed_prev,
                by = "age",
                all.x = TRUE) %>% dplyr::mutate(survey = serodata$survey[1])
  if (bin_data) {
    # I added this here for those cases when binned is prefered for plotting
    if (serodata$age_max[1] - serodata$age_min[1] < 3) {
    xx <- prepare_bin_data(serodata)
      prev_expanded <-
        base::merge(prev_expanded, xx, by = "age", all.x = TRUE)
    } else {
      prev_expanded <- prev_expanded %>% dplyr::mutate(
        cut_ages = "original",
        bin_size = .data$sample_by_age,
        bin_pos = .data$positives,
        p_obs_bin = .data$prev_obs,
        p_obs_bin_l = .data$prev_obs_lower,
        p_obs_bin_u = .data$prev_obs_upper
      )
    }
  }

  return(prev_expanded)
}
