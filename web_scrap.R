web_scrap<-function(owner,name,n,wait){
  
  doc<-GET(paste0("https://github.com/",owner,"/",name,"/tags"))
  doc = htmlParse(doc)
  
  els = getNodeSet(doc, '//*[contains(concat( " ", @class, " " ), concat( " ", "date", " " ))] | //*[contains(concat( " ", @class, " " ), concat( " ", "tag-name", " " ))]')
  
  tmp<-data.table(date=sapply(els, function(el) xmlValue(el))[seq(1,length(els)-1,2)],
                  version=sapply(els, function(el) xmlValue(el))[seq(2,length(els),2)])
  
  lct <- Sys.getlocale("LC_TIME"); Sys.setlocale("LC_TIME", "C")
  
  for(i in 1:n){
    if(i%%50==0){print(i)}
    doc<-GET(paste0("https://github.com/",owner,"/",name,"/tags?after=",tmp$version[nrow(tmp)]))
    doc = htmlParse(doc)
    
    els = getNodeSet(doc, '//*[contains(concat( " ", @class, " " ), concat( " ", "date", " " ))] | //*[contains(concat( " ", @class, " " ), concat( " ", "tag-name", " " ))]')
    if(length(els)==0){
      print(i)
      break
      }
    tmp<-rbind(tmp,data.table(date=sapply(els, function(el) xmlValue(el))[seq(1,length(els)-1,2)],
                              version=sapply(els, function(el) xmlValue(el))[seq(2,length(els),2)]))
    Sys.sleep(wait);
    if(nrow(tmp)%%10!=0|tmp$date[nrow(tmp)]=="NULL"){
      print(i)
      break}}
  
  tmp<-tmp[date!="NULL"]
  final_scp<-data.table(owner=owner,name=name,tmp)
  
  # final formatting
  final_scp[,date:=as.Date(gsub("[[:space:]]","",date),"%b%e,%Y")]
  final_scp[,version_ext:=str_extract(version,"\\d*\\.\\d*\\.\\d*")]
  
  Sys.setlocale("LC_TIME", lct)
  
  return(final_scp)
}