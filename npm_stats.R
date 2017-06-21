
doc<-jsonlite::fromJSON("https://registry.npmjs.org/react")
str(doc,1)

str(doc$versions,1)
str(doc$`dist-tags`,1)

str(doc$versions$`15.5.0`,1)

str(doc$versions$`15.5.0`)

url<-paste0('https://api.npmjs.org/downloads/range/','2016-01-01',':','2017-06-03','/',"react") 

temp<-fromJSON(url)
str(temp)

temp<-data.table(temp$downloads)
temp[,week:=paste0(year(day),"-W",sprintf('%02d',week(day)))]

ggplot(temp[,.(downloads=sum(downloads)),by=.(week)],aes(week,downloads,group=1))+geom_line()+theme_bw()+theme(axis.text.x = element_text(angle=90))

ggsave(file="images/react_npm.png",width=15,height=12,units="cm")
