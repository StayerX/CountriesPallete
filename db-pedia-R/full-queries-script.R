library(SPARQL) # SPARQL querying package
library(stringr)
# Step 1 - Set up preliminaries and define query
# Define the data.gov endpoint
endpoint <- "http://dbpedia.org/sparql"

# Coutries ----------------------------------------------------------------

# countries file # ToDo should replace with read from postgress in future
file<-"C:\\Users\\CBLadmin\\Dropbox\\repo\\CountriesPallete\\CountriesWith3AlphaCode.txt"
# countries file # ToDo should replace with read from postgress in future
fileCOutriesDB<-"C:\\Users\\CBLadmin\\Dropbox\\repo\\CountriesPallete\\CountriesQuery.csv"
# DB
countries<-read.csv(file,sep="\t",header=FALSE)
dimnames(countries)[[2]]<-list("code","name")
renew<-FALSE



# Database
require(sqldf)#for validation of connection
require(RPostgreSQL)
###
# Parameters Setup
###
# countries file # ToDo should replace with read from postgress in future
file<-"/Users/smeriwether/Development/CountriesPallete/CountriesWith3AlphaCode.txt"
# DB
Connection <- list(host="localhost", user="smeriwether", password="", dbname="countries_pallete",port="5432")
tableName<-"country_datas";
#Fields to extract
fields<-list(population="Total population",gni="Gross national income",life_expectancy="Life expectancy",dying_under_five="Probability of dying under",dying_between_sixty="Probability of dying between",expenditure_per_capita="Total expenditure on health per capita",expenditure_as_gdp="Total expenditure on health as % of GDP")
###
# Code
###
CheckDatabase <- function(Connection) {
  options(sqldf.RPostgreSQL.user      = Connection$user,
          sqldf.RPostgreSQL.password  = Connection$password,
          sqldf.RPostgreSQL.dbname    = Connection$dbname,
          sqldf.RPostgreSQL.host      = Connection$host,
          sqldf.RPostgreSQL.port      = Connection$port)
  
  out <- tryCatch(
    {
      sqldf("select TRUE;")
    },
    error=function(cond) {
      out <- FALSE
    }
  )
  return(out)
}


if (!CheckDatabase(Connection)) {
  stop("Not valid PostgreSQL connection.") 
} else {
  message("PostgreSQL connection is valid.")
}



con <- dbConnect(PostgreSQL(), host=Connection$host, user= Connection$user, password=Connection$password, dbname=Connection$dbname, port=Connection$port)


if(renew){
  # create query statement
  query <-'select ?country_name,?country, ?capital
  where {
  ?country rdfs:label ?country_name.
  ?country rdf:type umbel-rc:Country.
  ?country dbp:capital ?capital.
  MINUS { ?country dbp:yearEnd ?end }.       
  FILTER(LANG(?country_name) = "" || LANGMATCHES(LANG(?country_name), "en"))
  }'
  
  # Step 2 - Use SPARQL package to submit query and save results to a data frame
  qd <- SPARQL(endpoint,query)
  df <- qd$results
  write.csv(file=fileCOutriesDB,df,row.names = FALSE)
}else{
  df<-read.csv(file=fileCOutriesDB)
}
clearName<-function(name){
  #name<-"\"�.land Islands\"@en"
  name<-iconv(name, to='ASCII//TRANSLIT') 
  name<-str_replace_all(name, "@en", "")
  name<-str_replace_all(name, "[[:punct:]]", "")
}

countries$name_cleaned <- unlist(lapply(countries$name,clearName))
df$country_name_cleared <- unlist(lapply(df$country_name,clearName))
countries$matching_id <- vector(mode = "logical",length=length(countries$name_cleaned))
for( country in countries$name_cleaned){
  id<-grep(country, df$country_name_cleared)
  if(length(id)>0){
    countries[countries$name_cleaned==country,]$matching_id<-id[1]
  }else{
    # warning(country)
  }
}



# Music -------------------------------------------------------------------

for( countryID in 1:dim(countries)[[1]]){
  if(countries$matching_id[countryID]==0){next;}
  # create query statement
  query <-paste("
select ?country, ?capital, ?largestCity, ?pop, ?band
where {
                ?country rdf:type umbel-rc:Country.
                ?country dbp:capital ?capital.
                ?country dbp:largestCity ?largestCity.
                ?country dbp:populationCensus  ?pop.
                MINUS { ?country dbp:yearEnd ?end }.
                ?band rdf:type <http://schema.org/MusicGroup>.
                ?band dbo:hometown ?capital.
                VALUES ?country {",df$country[countries$matching_id[countryID]],"}. 
} ORDER BY DESC(xsd:Integer(?pop))
                LIMIT 100"  ,sep="")
  cat(query)
  # Step 2 - Use SPARQL package to submit query and save results to a data frame
  qd <- SPARQL(endpoint,query)
  dfmusic <- qd$results
  if(length(dfmusic)==0){next;}
  
  
  
}
