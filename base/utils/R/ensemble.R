#-------------------------------------------------------------------------------
# Copyright (c) 2012 University of Illinois, NCSA.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the 
# University of Illinois/NCSA Open Source License
# which accompanies this distribution, and is available at
# http://opensource.ncsa.illinois.edu/license.html
#-------------------------------------------------------------------------------

##' Reads output from model ensemble
##'
##' Reads output for an ensemble of length specified by \code{ensemble.size} and bounded by \code{start.year} 
##' and \code{end.year}
##'
##' DEPRECATED: This function has been moved to the \code{PEcAn.uncertainty} package.
##' The version in \code{PEcAn.utils} is deprecated, will not be updated to add any new features,
##' and will be removed in a future release of PEcAn.
##' Please use \code{PEcAn.uncertainty::read.ensemble.output} instead.
##'
##' @title Read ensemble output
##' @return a list of ensemble model output 
##' @param ensemble.size the number of ensemble members run
##' @param pecandir specifies where pecan writes its configuration files
##' @param outdir directory with model output to use in ensemble analysis
##' @param start.year first year to include in ensemble analysis
##' @param end.year last year to include in ensemble analysis
##' @param variables target variables for ensemble analysis
##' @export
##' @author Ryan Kelly, David LeBauer, Rob Kooper
#--------------------------------------------------------------------------------------------------#
read.ensemble.output <- function(ensemble.size, pecandir, outdir, start.year, end.year, 
                                 variable, ens.run.ids = NULL) {

  .Deprecated(
    new = "PEcAn.uncertainty::read.ensemble.output",
    msg = paste(
      "read.ensemble.output has been moved to PEcAn.uncertainty and is deprecated from PEcAn.utils.",
      "Please use PEcAn.uncertainty::read.ensemble.output instead.",
      "PEcAn.utils::read.ensemble.output will not be updated and will be removed from a future version of PEcAn.",
      sep = "\n"))

  if (is.null(ens.run.ids)) {
    samples.file <- file.path(pecandir, "samples.Rdata")
    if (file.exists(samples.file)) {
      load(samples.file)
      ens.run.ids <- runs.samples$ensemble
    } else {
      stop(samples.file, "not found required by read.ensemble.output")
    }
  }

  expr <- variable$expression
  variables <- variable$variables
  
  ensemble.output <- list()
  for (row in rownames(ens.run.ids)) {
    run.id <- ens.run.ids[row, "id"]
    PEcAn.logger::logger.info("reading ensemble output from run id: ", run.id)
    
    for(var in seq_along(variables)){
      out.tmp <- read.output(run.id, file.path(outdir, run.id), start.year, end.year, variables[var])
      assign(variables[var], out.tmp[[variables[var]]])
    }
    
    # derivation
    out <- eval(parse(text = expr))
    
    ensemble.output[[row]] <- mean(out, na.rm= TRUE) 
    
  }
  return(ensemble.output)
} # read.ensemble.output


##' Get parameter values used in ensemble
##'
##' DEPRECATED: This function has been moved to the \code{PEcAn.uncertainty} package.
##' The version in \code{PEcAn.utils} is deprecated, will not be updated to add any new features,
##' and will be removed in a future release of PEcAn.
##' Please use \code{PEcAn.uncertainty::get.ensemble.samples} instead.

##' Returns a matrix of randomly or quasi-randomly sampled trait values 
##' to be assigned to traits over several model runs.
##' given the number of model runs and a list of sample distributions for traits
##' The model run is indexed first by model run, then by trait
##' 
##' @title Get Ensemble Samples
##' @name get.ensemble.samples
##' @param ensemble.size number of runs in model ensemble
##' @param pft.samples random samples from parameter distribution, e.g. from a MCMC chain  
##' @param env.samples env samples
##' @param method the method used to generate the ensemble samples. Random generators: uniform, uniform with latin hypercube permutation. Quasi-random generators: halton, sobol, torus. Random generation draws random variates whereas quasi-random generation is deterministic but well equidistributed. Default is uniform. For small ensemble size with relatively large parameter number (e.g ensemble size < 5 and # of traits > 5) use methods other than halton. 
##' @param param.names a list of parameter names that were fitted either by MA or PDA, important argument, if NULL parameters will be resampled independently
##' 
##' @return matrix of (quasi-)random samples from trait distributions
##' @export
##' @author David LeBauer, Istem Fer
get.ensemble.samples <- function(ensemble.size, pft.samples, env.samples, 
                                 method = "uniform", param.names = NULL, ...) {
  
  .Deprecated(
    new = "PEcAn.uncertainty::get.ensemble.samples",
    msg = paste(
      "get.ensemble.samples has been moved to PEcAn.uncertainty and is deprecated from PEcAn.utils.",
      "Please use PEcAn.uncertainty::get.ensemble.samples instead.",
      "PEcAn.utils::get.ensemble.samples will not be updated and will be removed from a future version of PEcAn.",
      sep = "\n"))

  if (is.null(method)) {
    PEcAn.logger::logger.info("No sampling method supplied, defaulting to uniform random sampling")
    method <- "uniform"
  }
  
  ## force as numeric for compatibility with Fortran code in halton()
  ensemble.size <- as.numeric(ensemble.size)
  if (ensemble.size <= 0) {
    ans <- NULL
  } else if (ensemble.size == 1) {
    ans <- get.sa.sample.list(pft.samples, env.samples, 0.5)
  } else {
    pft.samples[[length(pft.samples) + 1]] <- env.samples
    names(pft.samples)[length(pft.samples)] <- "env"
    pft2col <- NULL
    for (i in seq_along(pft.samples)) {
      pft2col <- c(pft2col, rep(i, length(pft.samples[[i]])))
    }
    

    total.sample.num <- sum(sapply(pft.samples, length))
    random.samples <- NULL
    
    
    if (method == "halton") {
      need_packages("randtoolbox")
      PEcAn.logger::logger.info("Using ", method, "method for sampling")
      random.samples <- randtoolbox::halton(n = ensemble.size, dim = total.sample.num, ...)
      ## force as a matrix in case length(samples)=1
      random.samples <- as.matrix(random.samples)
    } else if (method == "sobol") {
      need_packages("randtoolbox")
      PEcAn.logger::logger.info("Using ", method, "method for sampling")
      random.samples <- randtoolbox::sobol(n = ensemble.size, dim = total.sample.num, ...)
      ## force as a matrix in case length(samples)=1
      random.samples <- as.matrix(random.samples)
    } else if (method == "torus") {
      need_packages("randtoolbox")
      PEcAn.logger::logger.info("Using ", method, "method for sampling")
      random.samples <- randtoolbox::torus(n = ensemble.size, dim = total.sample.num, ...)
      ## force as a matrix in case length(samples)=1
      random.samples <- as.matrix(random.samples)
    } else if (method == "lhc") {
      need_packages("PEcAn.emulator")
      PEcAn.logger::logger.info("Using ", method, "method for sampling")
      random.samples <- PEcAn.emulator::lhc(t(matrix(0:1, ncol = total.sample.num, nrow = 2)), ensemble.size)
    } else if (method == "uniform") {
      PEcAn.logger::logger.info("Using ", method, "random sampling")
      # uniform random
      random.samples <- matrix(stats::runif(ensemble.size * total.sample.num),
                               ensemble.size, 
                               total.sample.num)
    } else {
      PEcAn.logger::logger.info("Method ", method, " has not been implemented yet, using uniform random sampling")
      # uniform random
      random.samples <- matrix(stats::runif(ensemble.size * total.sample.num),
                               ensemble.size, 
                               total.sample.num)
    }
    
    
    ensemble.samples <- list()
    
    
    col.i <- 0
    for (pft.i in seq(pft.samples)) {
      ensemble.samples[[pft.i]] <- matrix(nrow = ensemble.size, ncol = length(pft.samples[[pft.i]]))
      
      # meaning we want to keep MCMC samples together
      if(length(pft.samples[[pft.i]])>0 & !is.null(param.names)){ 
        # TODO: for now we are sampling row numbers uniformly
        # stop if other methods were requested 
        if(method != "uniform"){
          PEcAn.logger::logger.severe("Only uniform sampling is available for joint sampling at the moment. Other approaches are not implemented yet.")
        }
        same.i <- sample.int(length(pft.samples[[pft.i]][[1]]), ensemble.size)
      }
      
      for (trait.i in seq(pft.samples[[pft.i]])) {
        col.i <- col.i + 1
        if(names(pft.samples[[pft.i]])[trait.i] %in% param.names[[pft.i]]){ # keeping samples
          ensemble.samples[[pft.i]][, trait.i] <- pft.samples[[pft.i]][[trait.i]][same.i]
        }else{
          ensemble.samples[[pft.i]][, trait.i] <- stats::quantile(pft.samples[[pft.i]][[trait.i]],
                                                                  random.samples[, col.i])
        }
      }  # end trait
      ensemble.samples[[pft.i]] <- as.data.frame(ensemble.samples[[pft.i]])
      colnames(ensemble.samples[[pft.i]]) <- names(pft.samples[[pft.i]])
    }  #end pft
    names(ensemble.samples) <- names(pft.samples)
    ans <- ensemble.samples
  }
  return(ans)
} # get.ensemble.samples


##' Write ensemble config files
##'
##' DEPRECATED: This function has been moved to the \code{PEcAn.uncertainty} package.
##' The version in \code{PEcAn.utils} is deprecated, will not be updated to add any new features,
##' and will be removed in a future release of PEcAn.
##' Please use \code{PEcAn.uncertainty::write.ensemble.configs} instead.
##'
##' Writes config files for use in meta-analysis and returns a list of run ids.
##' Given a pft.xml object, a list of lists as supplied by get.sa.samples, 
##' a name to distinguish the output files, and the directory to place the files.
##' @title Write ensemble configs 
##' @param defaults pft
##' @param ensemble.samples list of lists supplied by \link{get.ensemble.samples}
##' @param settings list of PEcAn settings
##' @param write.config a model-specific function to write config files, e.g. \link{write.config.ED}  
##' @param clean remove old output first?
##' @return list, containing $runs = data frame of runids, and $ensemble.id = the ensemble ID for these runs. Also writes sensitivity analysis configuration files as a side effect
##' @export
##' @author David LeBauer, Carl Davidson
write.ensemble.configs <- function(defaults, ensemble.samples, settings, model, 
                                   clean = FALSE, write.to.db = TRUE) {
  
  .Deprecated(
    new = "PEcAn.uncertainty::write.ensemble.configs",
    msg = paste(
      "write.ensemble.configs has been moved to PEcAn.uncertainty and is deprecated from PEcAn.utils.",
      "Please use PEcAn.uncertainty::write.ensemble.configs instead.",
      "PEcAn.utils::write.ensemble.configs will not be updated and will be removed from a future version of PEcAn.",
      sep = "\n"))

  my.write.config <- paste("write.config.", model, sep = "")
  
  if (is.null(ensemble.samples)) {
    return(list(runs = NULL, ensemble.id = NULL))
  }
  
  # Open connection to database so we can store all run/ensemble information
  if (write.to.db) {
    con <- try(PEcAn.DB::db.open(settings$database$bety), silent = TRUE)
    if (inherits(con, "try-error")) {
      con <- NULL
    } else {
      on.exit(PEcAn.DB::db.close(con))
    }
  } else {
    con <- NULL
  }
  
  # Get the workflow id
  if ("workflow" %in% names(settings)) {
    workflow.id <- settings$workflow$id
  } else {
    workflow.id <- -1
  }
  
  # create an ensemble id
  if (!is.null(con)) {
    # write ensemble first
    ensemble.id <- PEcAn.DB::db.query(paste0(
      "INSERT INTO ensembles (runtype, workflow_id) ",
      "VALUES ('ensemble', ", format(workflow.id, scientific = FALSE), ")",
      "RETURNING id"), con = con)[['id']]

    for (pft in defaults) {
      PEcAn.DB::db.query(paste0(
        "INSERT INTO posteriors_ensembles (posterior_id, ensemble_id) ",
        "values (", pft$posteriorid, ", ", ensemble.id, ")"), con = con)
    }
  } else {
    ensemble.id <- NA
  }
  
  # find all inputs that have an id
  inputs <- names(settings$run$inputs)
  inputs <- inputs[grepl(".id$", inputs)]
  
  # write configuration for each run of the ensemble
  runs <- data.frame()
  for (counter in seq_len(settings$ensemble$size)) {
    if (!is.null(con)) {
      paramlist <- paste("ensemble=", counter, sep = "")
      run.id <- PEcAn.DB::db.query(paste0(
        "INSERT INTO runs (model_id, site_id, start_time, finish_time, outdir, ensemble_id, parameter_list) ",
        "values ('", 
          settings$model$id, "', '", 
          settings$run$site$id, "', '", 
          settings$run$start.date, "', '", 
          settings$run$end.date, "', '", 
          settings$run$outdir, "', ", 
          ensemble.id, ", '", 
          paramlist, "') ",
        "RETURNING id"), con = con)[['id']]
      
      # associate inputs with runs
      if (!is.null(inputs)) {
        for (x in inputs) {
          PEcAn.DB::db.query(paste0("INSERT INTO inputs_runs (input_id, run_id) ",
                          "values (", settings$run$inputs[[x]], ", ", run.id, ")"), 
                   con = con)
        }
      }
      
    } else {
      run.id <- get.run.id("ENS", left.pad.zeros(counter, 5))
    }
    runs[counter, "id"] <- run.id
    
    # create folders (cleaning up old ones if needed)
    if (clean) {
      unlink(file.path(settings$rundir, run.id))
      unlink(file.path(settings$modeloutdir, run.id))
    }
    dir.create(file.path(settings$rundir, run.id), recursive = TRUE)
    dir.create(file.path(settings$modeloutdir, run.id), recursive = TRUE)
    
    # write run information to disk
    cat("runtype     : ensemble\n",
        "workflow id : ", workflow.id, "\n",
        "ensemble id : ", ensemble.id, "\n",
        "run         : ", counter, "/", settings$ensemble$size, "\n",
        "run id      : ", run.id, "\n",
        "pft names   : ", as.character(lapply(settings$pfts, function(x) x[['name']])), "\n",
        "model       : ", model, "\n",
        "model id    : ", settings$model$id, "\n",
        "site        : ", settings$run$site$name, "\n",
        "site  id    : ", settings$run$site$id, "\n",
        "met data    : ", settings$run$site$met, "\n",
        "start date  : ", settings$run$start.date, "\n",
        "end date    : ", settings$run$end.date, "\n",
        "hostname    : ", settings$host$name, "\n",
        "rundir      : ", file.path(settings$host$rundir, run.id), "\n",
        "outdir      : ", file.path(settings$host$outdir, run.id), "\n",
        file = file.path(settings$rundir, run.id, "README.txt"))
    
    do.call(my.write.config, args = list(
      defaults = defaults, 
      trait.values = lapply(
        ensemble.samples, function(x, n) { x[n, , drop=FALSE] }, n=counter
      ), 
      settings = settings, 
      run.id = run.id)
    )
    cat(run.id, file = file.path(settings$rundir, "runs.txt"), sep = "\n", append = TRUE)
  }

  return(invisible(list(runs = runs, ensemble.id = ensemble.id)))
} # write.ensemble.configs
