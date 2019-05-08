library(ROracle)
library(dplyr)
library(ggplot2)
library(tidyr)
library(reshape2)
library(RColorBrewer)

get_ash_data <- function(ch, category, groupby=category, alias=category, filter="1=1", weight="1", ytitle='aas', t1=format(Sys.Date()-14, "%Y-%m-%d %H:%M:%S"), t2=format(Sys.Date()+1, "%Y-%m-%d %H:%M:%S"), res='hh24', top.n.categories=10, dash=TRUE)
{
  print(paste0('category=', category))
  print(paste0('groupby=', groupby))
  print(paste0('alias=', alias))
  print(paste0('filter=', filter))
  print(paste0('weight=', weight))
  
  table <- 'GV$ACTIVE_SESSION_HISTORY'
  samples_per_min <- 60
  if(dash) {
    table <- 'DBA_HIST_ACTIVE_SESS_HISTORY'
    if (weight==1) samples_per_min <- 6
  }
  
  ashQueryText <-                     "select trunc(sample_time, ':res:') t, 
                                                 :category: :alias:, 
  sum(:weight:)/:samples_per_min:/:mins: :ytitle: 
  from :table: ash 
  where 1=1
  and :filter: 
  and sample_time between timestamp':t1:' and timestamp':t2:'
  group by trunc(sample_time, ':res:'), :groupby: 
  order by trunc(sample_time, ':res:'), :category:"
  
#  if (weight=="1"){
#    print(weight)
    if(res=="dd") {
      mins = 60*24
    } else if(res=="hh24") {
      mins = 60
    } else {
      mins = 1
    }
#  }
#  else mins = 1/6
  
  ashQueryText <- gsub(":weight:", weight, ashQueryText)
  ashQueryText <- gsub(":res:", res, ashQueryText)
  ashQueryText <- gsub(":ytitle:", ytitle, ashQueryText)
  ashQueryText <- gsub(":mins:", mins, ashQueryText)
  ashQueryText <- gsub(":samples_per_min:", samples_per_min, ashQueryText)
  ashQueryText <- gsub(":category:", category, ashQueryText)
  ashQueryText <- gsub(":groupby:", groupby, ashQueryText)
  ashQueryText <- gsub(":alias:", alias, ashQueryText)
  ashQueryText <- gsub(":filter:", filter, ashQueryText)
  ashQueryText <- gsub(":t1:", t1, ashQueryText)
  ashQueryText <- gsub(":t2:", t2, ashQueryText)
  ashQueryText <- gsub(":table:", table, ashQueryText)
  print(ashQueryText)
  q <- dbGetQuery(ch, ashQueryText)
  if(is.null(nrow(q))) stop(q)
  return(q)
}

plot_ash_data <- function(d, basepalette='Dark2'){
  cols <- colorRampPalette(brewer.pal(8, basepalette))
  mycols <- cols(length(unique(d[,2])))
  p = ggplot(d, aes_string(x = names(d)[[1]], y = names(d)[[3]]), label='T') + 
    geom_area(stat='identity', aes_string(fill=names(d)[2])) + 
    scale_fill_manual(values=mycols)
#  ggplotly(p, tooltip=text)
}

plot_ash <- function(ch, category, alias=category, groupby=category, filter="1=1", weight=1, ytitle='aas', t1=format(Sys.Date()-14, "%Y-%m-%d %H:%M:%S"), t2=format(Sys.Date()+1, "%Y-%m-%d %H:%M:%S"), res='hh24', n=5, dash=TRUE, basepalette='Dark2'){
  print("getting data...")
  data <- get_ash_data(ch, 
                       category=category, 
                       groupby=groupby, 
                       alias=alias, 
                       filter=filter, 
                       weight=weight, 
                       ytitle=ytitle, 
                       t1=t1, 
                       t2=t2, 
                       res=res, 
                       dash=dash)
  oldnames <- names(data)
#  print(head(data))
  print("gott the data")
  data[,2] <- myfactor(data[,2], data[,3], n)
  data <- aggregate(data[,3], by=list(data[,1], data[,2]), FUN=sum)
  names(data) <- oldnames
  
  data[,2] <- reorder(data[,2], data[,3])
  data <- spread_(data, key=oldnames[[2]], value=oldnames[[3]], fill=0)
  time_unit = 'day'
  if(res=="mi")
  {
    time_unit = "min"
  } else if (res=="hh24") {
    time_unit = "hour"
  }
  print(time_unit)
  all_minutes <- data.frame(T=seq(min(data[,1]), max(data[,1]), time_unit))
  data <- merge(all_minutes, data, all=TRUE)
  data <- melt(data, id.vars = oldnames[[1]])
  names(data) <- oldnames
  data[is.na(data[,3]), 3] <- 0
  print(paste0('basepalette=', basepalette))
  p = plot_ash_data(data, basepalette) + scale_y_continuous(expand=c(0,0))
  return(p)
#  return(data)
}
  
hotfactor= function(fac,by,n=10,o="other") {
  levels(fac)[rank(-xtabs(by~fac))[levels(fac)]>n] <- o
  fac
}

myfactor <- function(fac, val, n){
  n <- as.numeric(n)
  fac <- as.character(fac)
  aggr <- aggregate(val, by=list(fac=fac), sum, na.rm=T)
  topn <- as.character(head(arrange(aggr, -x)[,1],n))
  fac[! fac %in% topn] <- 'other'
  fac
}
