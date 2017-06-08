download_graphql<-function(owner,name,n=100,before=NA){
  
  qry <- Query$new()
  
  if(is.na(before)){
    qry$query(query, paste0('{
    repository(owner:"',owner,'", name:"',name,'") {
          description
          releases(last:',n,'){
          totalCount
          edges{
          cursor
          node{
          name
          url
          publishedAt
          }}}}}'))
    
  }

  if(!is.na(before)){
    qry$query(query, paste0('{
                            repository(owner:"',owner,'", name:"',name,'") {
                            description
                            releases(last:',n,' before:"',before,'"){
                            totalCount
                            edges{
                            cursor
                            node{
                            name
                            url
                            publishedAt
                            }}}}}'))
    
    }  
  
  result<-cli$exec(qry$queries$query)
  
  if(length(result$data$repository$releases$edges)==0){
    print("There is no info in GraphQL database")
    return(NULL)
  }
  
  return_data<-list("totalCount"=result$data$repository$releases$totalCount,
                    "data"=data.table(owner=owner,name=name,
                                      cursor=result$data$repository$releases$edges$cursor,
                                      result$data$repository$releases$edges$node))
  
  return(return_data)
}
