#### install packages

#install.packages("bigrquery")
#install.packages("prettyunits")

#install.packages('devtools') 
#devtools::install_github("rstats-db/bigrquery")
library(bigrquery)

library(data.table)
library(ggplot2)

#### download data ####
# Use your project ID here
project <- "httparchiveproject" # put your project ID here

dates<-c(paste0(2012:2017,"_01_01"),paste0(2012:2017,"_04_01"),paste0(2012:2016,"_07_01"),paste0(2012:2016,"_10_01"))


for(i in 1:length(dates)){
  sql <- paste0("SELECT pageid, url, rank, onLoad, fullyLoaded, reqTotal, reqHtml, reqJS, bytesTotal, bytesHtml, bytesJS FROM [httparchive:runs.",dates[i],"_pages] 
        WHERE rank IS NOT NULL and rank<10000
              ORDER BY rank asc")

  # Execute the query and store the result
  tmp <- query_exec(sql, project = project, max_pages = Inf)
  tmp<-data.table(tmp)
  tmp[,date:=dates[i]]
  
#  tmp[,jsI:=1]
#  tmp[,jsI:=as.numeric(cumsum(jsI)),by=pageid]

  ifelse(i==1,dataBQ<-tmp,dataBQ<-rbind(dataBQ,tmp))
  print(i)
}

dataBQ[,.N,by=date][order(date)]

save(dataBQ,file="data/dataBQ.RData")

ggplot(dataBQ[order(date)],aes(date, bytesJS/bytesTotal))+geom_boxplot()

ggplot(dataBQ[,.(bytesJS=mean(bytesJS,na.rm=T)),by=date][order(date)][date!="2017_01_01"],aes(date, bytesJS,group=1))+geom_line()+theme_bw()+
  theme(axis.text.x = element_text(angle=90))


ggplot(dataBQ[,.(bytesHtml=mean(bytesHtml,na.rm=T)),by=date][order(date)][date!="2017_01_01"],aes(date, bytesHtml,group=1))+geom_line()+theme_bw()+
  theme(axis.text.x = element_text(angle=90))


dataplot<-dataBQ[date!="2017_01_01"][,.(bytesHtml=mean(bytesHtml,na.rm=T),bytesJS=mean(bytesJS,na.rm=T)),by=date][order(date)]
dataplot[,growthHtml:=(bytesHtml/dataplot[date=="2012_01_01"]$bytesHtml)-1]
dataplot[,growthJS:=(bytesJS/dataplot[date=="2012_01_01"]$bytesJS)-1]

dataplot[,date:=as.Date(date,"%Y_%m_%d")]

ggplot(melt(dataplot[,.(date,growthHtml,growthJS)],"date"),aes(date,value*100,col=variable,group=variable))+geom_line()+geom_point(size=2)+
  geom_smooth()+
  theme_bw()+
  labs(x="",y="% growth",title="Growth of bytes count for Html and JS content \nstarting point: 2012-01-01")
ggsave(file="images/JSbytes.png",width=15,height=12,units="cm")

