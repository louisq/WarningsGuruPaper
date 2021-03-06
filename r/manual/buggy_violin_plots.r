vioplot2 <- function (x, ..., range = 1.5, h = NULL, ylim = NULL, names = NULL,
                      horizontal = FALSE, col = "magenta", border = "black", lty = 1,
                      lwd = 1, rectCol = "black", colMed = "white", pchMed = 19,
                      at, add = FALSE, wex = 1, drawRect = TRUE, side="both")
{
  datas <- list(x, ...)
  n <- length(datas)
  if (missing(at))
    at <- 1:n
  upper <- vector(mode = "numeric", length = n)
  lower <- vector(mode = "numeric", length = n)
  q1 <- vector(mode = "numeric", length = n)
  q2 <- vector(mode = "numeric", length = n)
  q3 <- vector(mode = "numeric", length = n)
  med <- vector(mode = "numeric", length = n)
  base <- vector(mode = "list", length = n)
  height <- vector(mode = "list", length = n)
  baserange <- c(Inf, -Inf)
  args <- list(display = "none")
  radj <- ifelse(side == "right", 0, 1)
  ladj <- ifelse(side == "left", 0, 1)
  if (!(is.null(h)))
    args <- c(args, h = h)
  med.dens <- rep(NA, n)
  for (i in 1:n) {
    data <- datas[[i]]
    data.min <- min(data)
    data.max <- max(data)
    q1[i] <- quantile(data, 0.25)
    q2[i] <- quantile(data, 0.5)
    q3[i] <- quantile(data, 0.75)
    med[i] <- median(data)
    iqd <- q3[i] - q1[i]
    upper[i] <- min(q3[i] + range * iqd, data.max)
    lower[i] <- max(q1[i] - range * iqd, data.min)
    est.xlim <- c(min(lower[i], data.min), max(upper[i],
                                               data.max))
    smout <- do.call("sm.density", c(list(data, xlim = est.xlim),
                                     args))
    med.dat <- do.call("sm.density",
                           c(list(data, xlim=est.xlim,
                              eval.points=med[i], display = "none")))
    med.dens[i] <- med.dat$estimate
    hscale <- 0.4/max(smout$estimate) * wex
    base[[i]] <- smout$eval.points
    height[[i]] <- smout$estimate * hscale
    med.dens[i] <- med.dens[i] * hscale
    t <- range(base[[i]])
    baserange[1] <- min(baserange[1], t[1])
    baserange[2] <- max(baserange[2], t[2])
  }
  if (!add) {
    xlim <- if (n == 1)
      at + c(-0.5, 0.5)
    else range(at) + min(diff(at))/2 * c(-1, 1)
    if (is.null(ylim)) {
      ylim <- baserange
    }
  }
  if (is.null(names)) {
    label <- 1:n
  }
  else {
    label <- names
  }
  boxwidth <- 0.05 * wex
  if (!add)
    plot.new()
  if (!horizontal) {
    if (!add) {
      plot.window(xlim = xlim, ylim = ylim)
      axis(2)
      axis(1, at = at, label = label)
    }
    box()
    for (i in 1:n) {
      polygon(x = c(at[i] - radj*height[[i]], rev(at[i] + ladj*height[[i]])),
              y = c(base[[i]], rev(base[[i]])),
              col = col, border = border,
              lty = lty, lwd = lwd)
      if (drawRect) {
        lines(at[c(i, i)], c(lower[i], upper[i]), lwd = lwd,
              lty = lty)
        rect(at[i] - radj*boxwidth/2,
             q1[i],
             at[i] + ladj*boxwidth/2,
             q3[i], col = rectCol)
        # median line segment
        lines(x = c(at[i] - radj*med.dens[i],
                  at[i],
                  at[i] + ladj*med.dens[i]),
              y = rep(med[i],3))
      }
    }
  }
  else {
    if (!add) {
      plot.window(xlim = ylim, ylim = xlim)
      axis(1)
      axis(2, at = at, label = label)
    }
    box()
    for (i in 1:n) {
      polygon(c(base[[i]], rev(base[[i]])),
              c(at[i] - radj*height[[i]], rev(at[i] + ladj*height[[i]])),
              col = col, border = border,
              lty = lty, lwd = lwd)
      if (drawRect) {
        lines(c(lower[i], upper[i]), at[c(i, i)], lwd = lwd,
              lty = lty)
        rect(q1[i], at[i] - radj*boxwidth/2, q3[i], at[i] +
               ladj*boxwidth/2, col = rectCol)
        lines(y = c(at[i] - radj*med.dens[i],
                    at[i],
                    at[i] + ladj*med.dens[i]),
              x = rep(med[i],3))
      }
    }
  }
  invisible(list(upper = upper, lower = lower, median = med,
                 q1 = q1, q3 = q3))
}


library("RPostgreSQL", lib.loc="~/R/x86_64-pc-linux-gnu-library/3.1")
library("vioplot", lib.loc="~/R/x86_64-pc-linux-gnu-library/3.1")                                                                 

con <- dbConnect(dbDriver("PostgreSQL"), dbname="cas", host="localhost")

buggy <- dbGetQuery(con, "select repo_name, warnings, new_warnings, jlint_warnings, new_jlint_warnings, findbugs_warnings,
new_findbugs_warnings, security_warnings, new_security_warnings, fallback_warnings, fallback_security_warnings,
build != 'BUILD' as build_failed, warnings > 0 as w_bool
from commits as c, commit_warning_summary as w where c.repository_id = w.repo and c.commit_hash = w.commit and contains_bug")

not_buggy <- dbGetQuery(con, "select repo_name, warnings, new_warnings, jlint_warnings, new_jlint_warnings, findbugs_warnings,
new_findbugs_warnings, security_warnings, new_security_warnings, fallback_warnings, fallback_security_warnings,
build != 'BUILD' as build_failed, warnings > 0 as w_bool
from commits as c, commit_warning_summary as w where c.repository_id = w.repo and c.commit_hash = w.commit and not contains_bug")


b_result = split(buggy, as.factor(buggy$repo_name))                                                             
b_commons_lang = b_result[['commons-lang']]$new_warnings
b_hadoop = b_result[['hadoop']]$new_warnings
b_ignite = b_result[['ignite']]$new_warnings
b_kylin = b_result[['kylin']]$new_warnings
b_phoenix = b_result[['phoenix']]$new_warnings
b_ranger = b_result[['ranger']]$new_warnings
b_tika = b_result[['tika']]$new_warnings
b_wicket = b_result[['wicket']]$new_warnings

n_result = split(not_buggy, as.factor(not_buggy$repo_name))
n_commons_lang = n_result[['commons-lang']]$new_warnings
n_hadoop = n_result[['hadoop']]$new_warnings
n_ignite = n_result[['ignite']]$new_warnings
n_kylin = n_result[['kylin']]$new_warnings
n_phoenix = n_result[['phoenix']]$new_warnings
n_ranger = n_result[['ranger']]$new_warnings
n_tika = n_result[['tika']]$new_warnings
n_wicket = n_result[['wicket']]$new_warnings

values <- c(b_commons_lang, n_commons_lang, b_hadoop, n_hadoop, b_ignite, n_ignite, b_kylin, n_kylin, b_phoenix, n_phoenix, b_ranger, n_ranger, b_tika, n_tika, b_wicket, n_wicket)
treatment <- c(
rep(c(1), each=length(b_commons_lang) + length(n_commons_lang)),
rep(c(2), each=length(b_hadoop)+ length(n_hadoop)),
rep(c(3), each=length(b_ignite)+ length(n_ignite)),
rep(c(4), each=length(b_kylin)+ length(n_kylin)),
rep(c(5), each=length(b_phoenix)+ length(n_phoenix)),
rep(c(6), each=length(b_ranger)+ length(n_ranger)),
rep(c(7), each=length(b_tika)+ length(n_tika)),
rep(c(8), each=length(b_wicket)+ length(n_wicket))
)

group <- c(
rep(c("1"), each=length(b_commons_lang)), rep(c("2"), each=length(n_commons_lang)),
rep(c("1"), each=length(b_hadoop)), rep(c("2"), each=length(n_hadoop)),
rep(c("1"), each=length(b_ignite)), rep(c("2"), each=length(n_ignite)),
rep(c("1"), each=length(b_kylin)), rep(c("2"), each=length(n_kylin)),
rep(c("1"), each=length(b_phoenix)), rep(c("2"), each=length(n_phoenix)),
rep(c("1"), each=length(b_ranger)), rep(c("2"), each=length(n_ranger)),
rep(c("1"), each=length(b_tika)), rep(c("2"), each=length(n_tika)),
rep(c("1"), each=length(b_wicket)), rep(c("2"), each=length(n_wicket))

)


require(vioplot)
require(devtools)
require(digest)


png(filename="/home/louisq/git/louis/authorship/thesis/r/figures/buggy_new_warnings_violin.png", width = 1000, height = 570, pointsize = 18)
plot(x=NULL, y=NULL,
     xlim = c(0.5, 8.5), ylim=c(min(values), max(values)),
     type="n", ann=FALSE, axes=F)
axis(1, at=c(1, 2, 3, 4, 5, 6, 7, 8),  labels=c("Commons-lang", "Hadoop", "Ignite", "Kylin", "Phoenix", "Ranger", "Tika", "Wicket"))
axis(2)
for (i in unique(treatment)) {
  for (j in unique(group)){
    vioplot2(values[which(treatment == i & group == j)],
             at = i,
             side = ifelse(j == 1, "left", "right"),
             col = ifelse(j == 1, "darkorange3", "lightblue"),
             add = T)
  }
}
title("New Warnings in Commits", xlab="Projects")
legend("topright", fill = c("darkorange3", "lightblue"),
       legend = c("Risky Commit", "Non Risky Commit"), box.lty=0)
dev.off()
