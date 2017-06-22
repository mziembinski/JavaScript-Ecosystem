npm_stats<-function(name,range1='2015-01-01',range2='2017-06-03',type="month"){

  url<-paste0('https://api.npmjs.org/downloads/range/',range1,':',range2,'/',name) 
  
  temp<-fromJSON(url)

  temp<-data.table(temp$downloads)
  temp[,week:=paste0(year(day),"-W",sprintf('%02d',week(day)))]
  temp[,month:=paste0(year(day),"-M",sprintf('%02d',month(day)))]
  
  if(type=="week"){
    temp<-temp[,.(downloads=sum(downloads)),by=.(week)]
    
    temp[shift(substr(week,7,9),1,type="lead")=="53",downloads:=downloads+shift(downloads,1,type="lead")]
    temp<-temp[substr(week,7,9)!="53"]
  }
  
  if(type=="month"){
    temp<-temp[,.(downloads=sum(downloads)),by=.(month)]
    }

  if(!(type %in% c("week","month"))){
    print("Error - the type not recognized")
    return()
  }
  
  return(temp)
}



