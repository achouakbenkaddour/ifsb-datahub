# 08_make_figures.R
# Reproduce the four publication figures for the JBNST Data Observer manuscript.
# Run from the repository root after 06_extract_takaful_panel.R.
# Figure captions and source notes belong in the manuscript, not inside PNG files.

source("scripts/00_setup.R")
suppressPackageStartupMessages({library(readr); library(dplyr); library(tidyr)})

f_panel <- file.path(dir_clean, "panel_takaful_harmonised.csv")
if (!file.exists(f_panel)) stop("Missing clean/panel_takaful_harmonised.csv. Run script 06 first.")
dir_fig <- file.path(getwd(), "figures"); dir.create(dir_fig, showWarnings=FALSE, recursive=TRUE)

p <- read_csv(f_panel, show_col_types=FALSE) %>% mutate(
  quarter=as.integer(quarter), year=as.integer(year), period=as.character(period),
  reporting_mode_std=tolower(trimws(as.character(reporting_mode)))) %>% arrange(iso3,year,quarter)
req <- c("iso3","country","period","year","quarter","reporting_mode_std","gwc_gen","gwc_gen_flux",
         "retention_gen","retention_fam","nwc_gen","opex_ratio_gen","invest_income_gen","penetr_gen","densite_gen","operateurs_gen")
miss <- setdiff(req,names(p)); if(length(miss)) stop("Missing required column(s): ",paste(miss,collapse=", "))
unknown <- setdiff(unique(na.omit(p$reporting_mode_std)),c("year-to-date","quarterly flow"))
if(length(unknown)) stop("Unexpected reporting_mode value(s): ",paste(unknown,collapse=", "))

# Figure 1: within-year reporting pattern ---------------------------------
f1 <- p %>% group_by(iso3,country,year) %>% mutate(
  q1=if(any(quarter==1 & is.finite(gwc_gen))) gwc_gen[quarter==1 & is.finite(gwc_gen)][1] else NA_real_,
  index_q1_100=ifelse(is.finite(q1)&q1!=0,100*gwc_gen/q1,NA_real_)) %>% ungroup() %>%
  filter(is.finite(index_q1_100),year>=2019,year<=2023)
if(!nrow(f1)) stop("Figure 1 data are empty after filtering.")
png(file.path(dir_fig,"figure1_reporting_pattern.png"),width=3273,height=2386,res=300,type="cairo")
par(mfrow=c(3,3),mar=c(3.2,3.5,2.4,1),oma=c(3.0,5.2,0.5,1),las=1,family="serif")
iso_order <- c("BHR","BRN","JOR","MYS","NGA","ARE","SAU"); ltys <- c(1,2,4,5,3); pchs <- c(16,15,17,18,8); yrs <- 2019:2023
for(cc in iso_order){
 d<-f1%>%filter(iso3==cc,is.finite(index_q1_100)); if(!nrow(d)){plot.new();title(main=cc);next}
 yr<-range(d$index_q1_100,na.rm=TRUE); if(!all(is.finite(yr))) stop("Non-finite y-range in Figure 1 for ",cc)
 if(diff(yr)==0) yr<-yr+c(-5,5); pad<-max(5,.06*diff(yr))
 plot(1:4,rep(NA_real_,4),type="n",xlim=c(1,4),ylim=c(max(0,yr[1]-pad),yr[2]+pad),xaxt="n",xlab="",ylab="",main=unique(d$country)[1],bty="l")
 axis(1,at=1:4,labels=paste0("Q",1:4)); abline(h=100,lty=3,col="grey55")
 for(i in seq_along(yrs)){z<-d%>%filter(year==yrs[i],is.finite(index_q1_100))%>%arrange(quarter);if(nrow(z))lines(z$quarter,z$index_q1_100,type="o",lty=ltys[i],pch=pchs[i],lwd=1.2,cex=.65,col="black")}
}
plot.new();legend("center",legend=yrs,lty=ltys,pch=pchs,ncol=3,bty="n",cex=.9,title="Year");plot.new()
mtext("Gross general contributions (Q1 = 100)", outer=TRUE, side=2, line=2.6, cex=.9, las=0)
dev.off()

# Figure 2: distortion from treating YTD as quarterly flow ----------------
f2 <- p %>% filter(reporting_mode_std=="year-to-date",quarter%in%2:4,is.finite(gwc_gen),is.finite(gwc_gen_flux),gwc_gen_flux!=0) %>%
 mutate(distortion=gwc_gen/gwc_gen_flux,qlabel=factor(paste0("Q",quarter),levels=c("Q2","Q3","Q4"))) %>% filter(is.finite(distortion))
if(!nrow(f2)||!all(c("Q2","Q3","Q4")%in%as.character(unique(f2$qlabel)))) stop("Figure 2 lacks required finite Q2-Q4 observations.")
means<-f2%>%group_by(qlabel)%>%summarise(m=mean(distortion),.groups="drop")%>%arrange(qlabel); mx<-f2%>%slice_max(distortion,n=1,with_ties=FALSE)
png(file.path(dir_fig,"figure2_ytd_distortion.png"),width=2864,height=1841,res=300,type="cairo")
par(mar=c(5.3,5.6,1.2,1.3),family="serif",las=1)
boxplot(distortion~qlabel,data=f2,outline=TRUE,col="white",border="black",xlab="Quarter",ylab="Published cumulative value / de-cumulated quarterly flow")
points(seq_len(nrow(means)),means$m,pch=18,cex=1.2);text(seq_len(nrow(means))+.07,means$m+.35,labels=sprintf("Mean %.2f",means$m),pos=4,cex=.82)
mx_x<-match(paste0("Q",mx$quarter[1]),levels(f2$qlabel));points(mx_x,mx$distortion[1],pch=8,cex=1.35);text(mx_x+.06,mx$distortion[1]-.35,labels=sprintf("%s %s: %.2f",mx$iso3[1],mx$period[1],mx$distortion[1]),pos=4,cex=.82)
dev.off()

# Figure 3: structured missingness (two-panel publication layout) ---------
vars <- c(gwc_gen="Gross contributions",nwc_gen="Net contributions",retention_gen="Retention ratio",opex_ratio_gen="Expense ratio",invest_income_gen="Investment income",penetr_gen="Penetration",densite_gen="Density",operateurs_gen="Operator count")
periods <- sprintf("%dQ%d", rep(2019:2023, each=4), rep(1:4, times=5))
iso_order <- c("BHR","BRN","JOR","MYS","NGA","ARE","SAU")
make_miss_matrix <- function(var_names){
  mat <- matrix(0, nrow=length(iso_order)*length(var_names), ncol=length(periods))
  labs <- character(nrow(mat)); r <- 1
  for(cc in iso_order) for(v in var_names){
    z <- p %>% filter(iso3==cc) %>% select(period, all_of(v))
    vals <- setNames(z[[v]], z$period); aligned <- vals[periods]
    mat[r,] <- as.numeric(!is.na(aligned)); labs[r] <- paste0(cc," - ",vars[[v]]); r <- r+1
  }
  list(mat=mat,labs=labs,nv=length(var_names))
}
draw_miss <- function(obj,panel){
  mat <- obj$mat; labs <- obj$labs; nv <- obj$nv
  image(seq_along(periods),seq_len(nrow(mat)),t(mat[nrow(mat):1,,drop=FALSE]),
        col=c("white","black"),breaks=c(-.5,.5,1.5),xaxt="n",yaxt="n",xlab="",ylab="",main=panel)
  axis(1,at=seq_along(periods),labels=periods,las=2,cex.axis=.58)
  axis(2,at=seq_len(nrow(mat)),labels=rev(labs),las=1,cex.axis=.52,col.axis="black")
  for(k in seq(nv+.5,nrow(mat)-.5,by=nv)) abline(h=k,col="grey55",lwd=.7)
  for(k in seq(4.5,length(periods)-.5,by=4)) abline(v=k,col="grey70",lwd=.7)
}
panelA_vars <- c("gwc_gen","nwc_gen","retention_gen","opex_ratio_gen")
panelB_vars <- c("invest_income_gen","penetr_gen","densite_gen","operateurs_gen")
png(file.path(dir_fig,"figure3_missingness_map.png"),width=2546,height=2721,res=300,type="cairo")
par(mfrow=c(2,1),mar=c(6.8,12.8,2.2,1.0),oma=c(.4,.4,.4,.4),family="serif",las=1)
draw_miss(make_miss_matrix(panelA_vars),"Panel A")
draw_miss(make_miss_matrix(panelB_vars),"Panel B")
dev.off()

# Figure 4: retention profiles by reporting mode --------------------------
make_profile <- function(var) bind_rows(
 p%>%filter(reporting_mode_std=="year-to-date")%>%group_by(quarter)%>%summarise(value=mean(.data[[var]],na.rm=TRUE),.groups="drop")%>%mutate(series="YTD group"),
 p%>%filter(reporting_mode_std=="quarterly flow")%>%group_by(quarter)%>%summarise(value=mean(.data[[var]],na.rm=TRUE),.groups="drop")%>%mutate(series="Quarterly-flow group"),
 p%>%filter(iso3=="NGA")%>%group_by(quarter)%>%summarise(value=mean(.data[[var]],na.rm=TRUE),.groups="drop")%>%mutate(series="Nigeria"))%>%filter(is.finite(value))
prof_g<-make_profile("retention_gen");prof_f<-make_profile("retention_fam"); styles<-list("YTD group"=list(lty=1,pch=16),"Quarterly-flow group"=list(lty=2,pch=15),"Nigeria"=list(lty=3,pch=17))
png(file.path(dir_fig,"figure4_retention_profiles.png"),width=3136,height=1636,res=300,type="cairo")
par(mfrow=c(1,2),mar=c(4.4,4.8,3.2,1),oma=c(3.4,1.5,.5,1),family="serif",las=1)
for(item in list(list(d=prof_g,title="General branch"),list(d=prof_f,title="Family branch"))){
 d<-item$d%>%filter(is.finite(value));if(!nrow(d))stop("Empty retention panel: ",item$title);yr<-range(d$value);if(!all(is.finite(yr)))stop("Non-finite retention range: ",item$title)
 plot(1:4,rep(NA_real_,4),type="n",xlim=c(1,4),ylim=c(min(55,yr[1]-3),max(112,yr[2]+3)),xaxt="n",xlab="",ylab="Mean published retention ratio (%)",main=item$title,bty="l")
 axis(1,at=1:4,labels=paste0("Q",1:4));abline(h=100,lty=4,col="grey50")
 for(s in names(styles)){z<-d%>%filter(series==s)%>%arrange(quarter);if(nrow(z)){st<-styles[[s]];lines(z$quarter,z$value,type="o",lty=st$lty,pch=st$pch,lwd=1.5,cex=.85,col="black")}}
}
par(fig=c(0,1,0,1),new=TRUE,mar=c(0,0,0,0));plot.new();legend("bottom",inset=.015,legend=names(styles),lty=vapply(styles,function(x)x$lty,numeric(1)),pch=vapply(styles,function(x)x$pch,numeric(1)),horiz=TRUE,bty="n",cex=.82)
dev.off()

message("08_make_figures.R : OK -> figure1_reporting_pattern.png, figure2_ytd_distortion.png, figure3_missingness_map.png, figure4_retention_profiles.png (300 dpi; captions/source notes external)")
