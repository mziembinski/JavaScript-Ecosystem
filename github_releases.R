packages<-c("data.table","ggplot2","jsonlite","curl","httr","stringr","scales",
            "ghql","graphql","XML","plotly","knitr","RColorBrewer")

#lapply(packages, install.packages)

lapply(c("plotly"), install.packages)
#devtools::install_github("schloerke/gqlr")

devtools::install_github("ropensci/ghql")

sapply(packages, require,character.only = TRUE)

library(XML)
library(plotly)

#### github graphql connection ####
# https://github.com/ropensci/ghql

token <- "f51147b8197d7d9d9421bf992a2dfbc758197ae9"
cli <- GraphqlClient$new(
  url = "https://api.github.com/graphql",
  headers = add_headers(Authorization = paste0("Bearer ", token))
)

#### github queries #### 
# https://developer.github.com/v4/explorer/

source('download_graphql.R')
source('check_repos.R')

temp<-download_graphql("facebook","react",100)
temp$totalCount

finalql<-temp$data
  
#angular
temp<-download_graphql("angular","angular",100) # if no graphql data go to webscrapping
# node
temp<-download_graphql("nodejs","node",100)
#ember
temp<-download_graphql("emberjs","ember.js",100)
temp$totalCount # should be more than 200 :/

finalql<-finalql[name!="ember.js"]

#vue
temp<-download_graphql("vuejs","vue",100)
temp$totalCount
finalql<-rbind(finalql,temp$data)

temp<-download_graphql("vuejs","vue",100,before=temp$data$cursor[1])
finalql<-rbind(finalql,temp$data)

# backbone
temp<-download_graphql("jashkenas","backbone",100)

# redux
temp<-download_graphql("reactjs","redux",100)

temp$totalCount

finalql<-rbind(finalql,temp$data)

# meteor
temp<-download_graphql("meteor","meteor",100)


# webpack
temp<-download_graphql("webpack","webpack",100)
### should be more :/

# check
finalql[,.N,by=owner]

# webscrapping
## because GraphQL and https://api.github.com/repos/angular/angular/releases gives empty arrays

source('web_scrap.R')

finalscp<-web_scrap("angular","angular",100,1)

#nodejs
temp<-web_scrap("nodejs","node",100,3)
temp
finalscp<-rbind(finalscp,temp)

#backbone
temp<-web_scrap("jashkenas","backbone",100,1)
temp
finalscp<-rbind(finalscp,temp)

#meteor
temp<-web_scrap("meteor","meteor",100,3)
temp
finalscp<-rbind(finalscp,temp)

#webpack
temp<-web_scrap("webpack","webpack",100,1)
temp
finalscp<-rbind(finalscp,temp)

#ember
temp<-web_scrap("emberjs","ember.js",100,2)
temp
finalscp<-rbind(finalscp,temp)

#nodejs
temp<-web_scrap("facebook","react",20,1)
temp
finalscp<-rbind(finalscp,temp)


# check
finalscp[,.N,by=.(owner,name)]

## save
save(finalql,finalscp,file="data/finals.RData")
load(file="data/finals.RData")

#### formatting ####

finalql
finalscp

final<-finalscp[,.(owner,name,date,version,version_ext)]

finalql[,date:=as.Date(publishedAt)]
finalql[,id:=.I]
finalql[,version:=gsub(paste0("https://github.com/",owner,"/",name,"/releases/tag/"),"",url),by=id]
finalql[,version_ext:=str_extract(url,"\\d*\\.\\d*\\.\\d*")]

final<-rbind(final,finalql[name!="react"][,.(owner,name,date,version,version_ext)])

write.csv(final,file="data/final.csv")

# summary
finalsm<-final[,.(date_min=min(date),date_max=max(date),
                  version_first=min(version),
                  version_last=max(version)),by=.(owner,name)]

final[final[,.(date=min(date)),by=.(owner,name)],on=.(owner,name,date)]

## checked manually with respective guthub pages
### first
finalsm[name=="angular",version_first:="0.0.1"]
finalsm[name=="webpack",version_first:="1.0.0"]
finalsm[name=="node",version_first:="0.0.1"]
finalsm[name=="meteor",version_first:="0.0.40"]
finalsm[name=="ember.js",version_first:="0.9"]
finalsm[name=="react",version_first:="0.3.0"]
finalsm[name=="vue",version_first:="0.6.0"]
finalsm[name=="redux",version_first:="0.2.0"]

### last
final[final[,.(date=max(date)),by=.(owner,name)],on=.(owner,name,date)]

finalsm
finalsm[name=="angular",version_last:="4.2.0"]
finalsm[name=="backbone",version_last:="1.3.3"]
finalsm[name=="webpack",version_last:="3.0.0"]
finalsm[name=="node",version_last:="8.0.0"]
finalsm[name=="meteor",version_last:="1.6"]
finalsm[name=="ember.js",version_last:="2.14.0"]
finalsm[name=="react",version_last:="15.5.4"]
finalsm[name=="vue",version_last:="2.3.3"]
finalsm[name=="redux",version_last:="3.6.0"]

finalsm[,.(owner,name,date_min,version_first,date_max,version_last)]

kable(finalsm[,.(owner,name,date_min,version_first,date_max,version_last)])

final[,c("V1","V2","V3"):=tstrsplit(version_ext,"\\.")]
final[,calculated_ver:=as.numeric(V1)*1e6+as.numeric(V2)*1e3+as.numeric(V3)]

#### react ####

final[name=="react"]

kable(final[name=="react"][,.(owner,name,date,version,version_ext)][order(-date)][1:10])

ggdata<-final[name=="react"]
ggdata[V1=="15",major:="15"]
ggdata[V1!="15",major:=V2]
ggdata[,major:=as.numeric(major)]

g<-ggplot(ggdata,aes(date,reorder(version_ext,calculated_ver),color=factor(major)))+
  geom_point(size=2)+
  theme_bw()+labs(y="versions",color="Major release",title="Releases dates")+
  theme(plot.title = element_text(hjust = 0.5))

ggsave(g,file="images/react2.png",width=15,height=12,units="cm")

temp<-ggdata[major!=0][,.(.N,date_first=min(date),date_last=max(date)),
             by=.(owner,name,major)]
temp[,previous:=shift(date_first,1,type="lead")]
temp[,since_release:=date_last-date_first]
temp[,since_previous:=date_first-previous]

kable(temp)

g<-ggplot(temp,aes(major,since_previous,fill=factor(major)))+
  geom_bar(stat="identity")+coord_flip()+
  theme_bw()+labs(x="Major release",y="",
                  fill="Major release",title="Days since first release of previous major")+
  theme(plot.title = element_text(hjust = 0.5))

ggsave(g,file="images/react_since.png",width=15,height=12,units="cm")

#### nodejs ####
final[name=="node"]

kable(final[name=="node"][,.(owner,name,date,version,version_ext)][order(-date)][1:10])

ggdata<-final[name=="node"][!is.na(V1)]
ggdata[,major:=as.numeric(V1)]

ggdata$version_ext

g<-ggplot(ggdata,aes(date,reorder(version_ext,calculated_ver),color=factor(major)))+
  geom_point(size=2)+
  theme_bw()+labs(y="versions",color="Major release",title="Releases dates")+
  theme(plot.title = element_text(hjust = 0.5),
        axis.ticks.y=element_blank(),
        axis.text.y = element_blank(),
        panel.grid.major.y=element_blank())
g
ggsave(g,file="images/node.png",width=15,height=12,units="cm")

p <- plot_ly(ggdata, x = ~date, y = ~reorder(version_ext,calculated_ver),
             color=~factor(major),colors=brewer.pal(9, "Paired"),
             type = 'scatter',mode = 'markers',
             text = ~paste('(Date,Version)'))%>%
  layout(xaxis = list(title="Date of the release"), yaxis = list(title="Version"))

p

temp<-ggdata[!is.na(major)][,.(.N,date_first=min(date),date_last=max(date)),
                       by=.(owner,name,major)]
setkey(temp,owner,name,major)
temp[,previous:=shift(date_first,1,type="lag")]
temp[,since_release:=date_last-date_first]
temp[,since_previous:=date_first-previous]

kable(temp[order(-major)])

g<-ggplot(temp,aes(major,since_previous,fill=factor(major)))+
  geom_bar(stat="identity")+coord_flip()+
  theme_bw()+labs(x="Major release",y="",
                  fill="Major release",title="Days since first release of previous major")+
  theme(plot.title = element_text(hjust = 0.5))

ggsave(g,file="images/node_since.png",width=15,height=12,units="cm")

#### plotting ####



## first
final_scp[,c("V1","V2","V3"):=tstrsplit(version,"\\.")]

final_scp[,calculated_ver:=as.numeric(V1)*1e6+as.numeric(V2)*1e3+as.numeric(V3)]

## only first
setkey(final_scp,owner,name,calculated_ver)
final_scp[!is.na(version),first:=1]
final_scp[calculated_ver==shift(calculated_ver,1),first:=0]

ggplot(final_scp[first==1],aes(date,calculated_ver))+geom_line()+theme_bw()+
  scale_y_continuous(label=comma,breaks=seq(0,16e6,1e6))

ggplot(final_scp[first==1],aes(date,calculated_ver))+geom_line()+geom_point()+
  theme_bw()+
  scale_y_continuous(label=comma,breaks=seq(0,16e6,1e6))

g<-ggplot(final_scp[first==1],aes(date,calculated_ver))+geom_line()+geom_point()+
  facet_grid(V1~.,scale="free")+
  theme_bw()+
  scale_y_continuous(label=comma,breaks=seq(0,16e6,1e6))
g

ggplotly(g)

#### extract date and version ####


final[,c("V1","V2","V3"):=tstrsplit(from_url,"\\.")]

final[name=="react"&V1==0,calculated_ver:=as.numeric(V2)*1e6+as.numeric(V3)*1e3]

final[name=="react"&V1!=0,calculated_ver:=as.numeric(V1)*1e6+as.numeric(V2)*1e3+as.numeric(V3)]

## only first
setkey(final,owner,name,calculated_ver)
final[,first:=1]
final[calculated_ver==shift(calculated_ver,1),first:=0]

ggplot(final[first==1],aes(date,calculated_ver))+geom_line()+theme_bw()+
  scale_y_continuous(label=comma,breaks=seq(0,16e6,1e6))
