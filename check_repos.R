check_repos<-function(owner,n=100){
  
  qry <- Query$new()
  
  qry$query('query', paste0('{
  repositoryOwner(login:"',owner,'"){
            login
            repositories(first:',n,'){
            totalCount
            nodes{
            name
            }}}}'))

  result<-cli$exec(qry$queries$query)
  
  if(length(result$data$repositoryOwner$repositories$nodes)==0){
    print("Error"); 
    return(NULL)
  }
  
  print(paste0("TotalCount:",result$data$repositoryOwner$repositories$totalCount))
  return(data.table(owner=owner,result$data$repositoryOwner$repositories$nodes))
  }

