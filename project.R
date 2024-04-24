library(arules)
library(arulesViz)
library(readxl)
library(ggplot2)
library(plyr)
library(RColorBrewer)
library(shiny)

itemslist=read_excel('data.xlsx')
itemslist=itemslist[complete.cases(itemslist),]
td=ddply(itemslist,c("BillNo","Date"),function(df1)paste(df1$Itemname,collapse=","
))

td$BillNo=NULL
td$Date=NULL
colnames(td)=c("items")
write.csv(td,'data1.csv',quote=FALSE,row.names = FALSE)
transactions=read.transactions('data1.csv',format='basket',sep=',') 
summary(transactions)
x=summary(transactions)
z=x@itemSummary
IQR(z)

itemFrequencyPlot(transactions,topN=20,type='absolute',col=brewer.pal(8,'Pastel2'),main='Absolute Item Frequency Plot')

generated.rules=apriori(transactions,parameter=list(supp=0.001,conf=0.8,maxlen=10))
generated.rules=sort(generated.rules,by='confidence',decreasing=TRUE)
summary(generated.rules)
inspect(generated.rules[1:10])

r=generated.rules[quality(generated.rules)$confidence>0.6]
plot(r)
top10rules=head(generated.rules,10, by='confidence',lbls=)
subs=head(generated.rules,16, by='confidence',lbls=)
plot(top10rules)
subs <- subs[-redundant]
recs <- unique(rhs(sort(subs, by = "lift")))
inspect(recs)



plot(subs, method = "graph")
plot(r, engine="plotly")
plot(top10rules, engine="plotly")
plot(subs, method = "grouped")
#outliers
rule_support <- quality(generated.rules)$support
summary(rule_support)
boxplot(rule_support, main = "Support Values of Association Rules Boxplot")

redundant <- which(colSums(is.subset(subs, subs)) > 1)
length(redundant)

subs <- subs[-redundant]
recs <- unique(rhs(sort(subs, by = "lift")))
inspect(recs)
plot(subs, method = "graph")

library(shiny)
library(arules)
library(arulesViz)
# Step 1: Read the data from the Excel file
itemslist <- read_excel("data.xlsx")

# Step 2: Preprocess the data
itemslist=itemslist[complete.cases(itemslist),]


# Assuming your data has a column named "TransactionID" and another column named "Item"
# Make sure your data is sorted by TransactionID to ensure correct conversion to transactions object
# You may need to perform additional preprocessing ba
# Step 3: Convert the data to a transactions objectsed on the structure of your data

transactions <- as(split(itemslist$Itemname, itemslist$BillNo), "transactions")

# Check the class of the transactions object
class(transactions)

# to read data, it has to be of two columns
#tr <- read.transactions("data.csv", format = "single", sep = ",", cols = c(1, 2), rm.duplicates = TRUE)

#data("Groceries")

items <- sample(transactions@itemInfo$labels, 100)

ar <- apriori(transactions,
              parameter = list(
                support = 0.001,
                confidence = 0.8,
                maxlen = 10
              ))

#plot(ar, method = "graph", engine = "htmlwidget")
#plot(ar, method = "paracoord")

# redundant <- which(colSums(is.subset(ar, ar)) > 1)
#
# ar <- ar[-redundant]

# Build UI.
ui <- fluidPage(titlePanel("Market Basket"),
                sidebarLayout(
                  sidebarPanel(
                    br(),
                    strong("Cart Item(s)"),
                    checkboxGroupInput(
                      "items",
                      label = "",
                      choices = items,
                      selected = sample(items, 3)
                    )
                  ),
                  mainPanel(
                    br(),
                    br(),
                    strong("Frequently Bought With: "),
                    tableOutput("recommendations"),
                    br(),
                    plotOutput("rulegraph")
                  )
                ))


server <- function(input, output) {
  recos <- reactive({
    subs <- subset(ar,
                   subset = lhs %in% input$items)
    s <- sort(subs, by = "confidence") 
    head(s)
  })
  
  output$recommendations <- renderTable({
   # tryCatch(
    #  expr = {
        recs <- data.frame()
        r <- recos()
        if (length(r) < 5) {
          recs <- r
        } else {
          recs <- r[1:5,]
        }
        recs <- unique(rhs(sort(recs, by = "lift")))
        inspect(recs)
      #},
      #error = function(error) {
     #   msg <- data.frame(msg = "Please Select an item!")
    #    colnames(msg) <- NULL
   #     msg
  #    }
    #)
  })
  
  output$rulegraph <- renderPlot({
    plot(recos(), method = "graph")
  })
  
}


shinyApp(ui, server)



