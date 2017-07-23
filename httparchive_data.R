#### install packages

#install.packages('devtools') 
#devtools::install_github("rstats-db/bigrquery")
library(bigrquery)
library(data.table)
library(ggplot2)
library(scales)

#### download data ####
# Use your project ID here
project <- "httparchiveproject" # put your project ID here

# Dates vector (there is no bytes data for 2017-01-01, so we add 2017-02-15 to the set)
dates<-c(paste0(2012:2016,"_01_01"),paste0(2012:2017,"_04_01"),paste0(2012:2016,"_07_01"),paste0(2012:2016,"_10_01"),"2017_02_15","2017_02_15")
dates<-dates[order(dates)]

# loop through dates and download data from google bigquery service
# for more expl. see: https://www.igvita.com/2013/06/20/http-archive-bigquery-web-performance-answers/
for(i in 1:length(dates)){
  sql <- paste0("SELECT pageid, url, rank, onLoad, fullyLoaded, reqTotal, reqHtml, reqJS,reqCSS, reqImg+reqGif+reqJpg+reqPng as reqPic,reqJson, bytesTotal, bytesHtml, bytesJS,bytesCSS, bytesImg+bytesGif+bytesJpg+bytesPng as bytesPic, bytesFont, bytesJson FROM [httparchive:runs.",dates[i],"_pages] 
        WHERE rank IS NOT NULL and rank<10000
              ORDER BY rank asc")

  # Execute the query and store the result
  tmp <- query_exec(sql, project = project, max_pages = Inf)
  tmp<-data.table(tmp)
  tmp[,date:=dates[i]]
  
  # combine results
  ifelse(i==1,dataBQ<-tmp,dataBQ<-rbind(dataBQ,tmp))
  # log loop progress
  print(paste0("Loop run: ",i,"; Ended at: ",format(Sys.time(), "%X")))
}

# check the results
dataBQ[,.N,by=date][order(date)]

# save the downloaded data 
save(dataBQ,file="data/dataBQ.RData")
load(file="data/dataBQ.RData")

#### plotting to check/explore data ####
ggplot(dataBQ[order(date)],aes(date, bytesJS/bytesTotal))+geom_boxplot()
p<-ggplot(dataBQ[order(date)],aes(date, bytesJS))+geom_boxplot()+theme_bw()+
  theme(axis.text.x = element_text(angle=90))+scale_y_continuous(labels = comma)


# compute lower and upper whiskers
ylim1 = boxplot.stats(dataBQ$bytesJS)$stats[c(1, 5)]

# scale y limits based on ylim1
p + coord_cartesian(ylim = ylim1*1.05)


#### chart mean and median ####
#html
#dataplot<-dataBQ[date!="2017_01_01"][,.(mean=mean(bytesHtml,na.rm=T),
                                        median=median(bytesHtml,na.rm=T)),by=date][order(date)]
#dataplot[,mean:=(mean/dataplot[date=="2012_01_01"]$mean)-1]
#dataplot[,median:=(median/dataplot[date=="2012_01_01"]$median)-1]

#dataplot[,date:=as.Date(date,"%Y_%m_%d")]

#ggplot(melt(dataplot[,.(date,mean,median)],"date"),aes(date,value*100,col=variable,group=variable))+geom_line()+geom_point(size=2)+
#  geom_smooth()+
#  facet_grid(variable~.,scale='free')+
#  theme_bw()+scale_color_manual(values=c('#253494','#0571b0'))+
#  labs(x="",y="% growth",title="Growth of bytes count for Html content \nstarting point: 2012-01-01")
#ggsave(file="images/htmlGrowth.png",width=15,height=12,units="cm")

#### chart mean ####
dataplot<-dataBQ[date!="2017_01_01"][,.(bytesHtml=mean(bytesHtml,na.rm=T),
                                        bytesJS=mean(bytesJS,na.rm=T),
                                        bytesCSS=mean(bytesCSS,na.rm=T),
                                        bytesPic=mean(bytesPic,na.rm=T)),by=date][order(date)]
dataplot[,growthHtml:=(bytesHtml/dataplot[date=="2012_01_01"]$bytesHtml)-1]
dataplot[,growthJS:=(bytesJS/dataplot[date=="2012_01_01"]$bytesJS)-1]
dataplot[,growthCSS:=(bytesCSS/dataplot[date=="2012_01_01"]$bytesCSS)-1]
dataplot[,growthPic:=(bytesPic/dataplot[date=="2012_01_01"]$bytesPic)-1]

dataplot[,date:=as.Date(date,"%Y_%m_%d")]

ggplot(melt(dataplot[,.(date,growthHtml,growthJS,growthCSS,growthPic)],"date"),aes(date,value*100,col=variable,group=variable))+geom_line()+geom_point(size=2)+
  geom_smooth(alpha=0.15)+
#  facet_grid(variable~.,scale='free')+
  theme_bw()+
  labs(x="",y="% growth",title="Growth of bytes count for web content")
ggsave(file="images/bytesGrowth.png",width=15,height=12,units="cm")

#### ####
dataBQ



