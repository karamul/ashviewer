library(shiny)
library(RColorBrewer)
library(plotly)

fluidPage(
  fluidRow(
    column(3,
           textInput("txtUsername", "User Name:", "username"),
           passwordInput("pwdDatabase", "Password:"),
           textInput("txtDatabase", "Database:", ""
           ),
           fluidRow(
             column(4,
                    actionButton("btnConnect", "Connect")
             ),
             column(4,
                    conditionalPanel(condition="input.category != ''", 
                                     actionButton("btnPlot", "Plot")
                    )
             )
           ),
           textOutput("connectStatus")
           
    ),
    column(3,
           checkboxInput("chkIncludeDash", "Switch to DBA_HIST version of ASH", value=FALSE),
           selectInput("weight", "what to plot:",
                       choices=list(
                         activity="1",
                         `write I/O requests`="delta_write_io_requests",
                         `read I/O requests`="delta_read_io_requests",
                         `write I/O bytes`="delta_write_io_bytes",
                         `read I/O bytes`="delta_read_io_bytes",
                         `TEMP bytes`='temp_space_allocated',
                         `PGA allocated (GB)`='pga_allocated/1024/1024/1024',
                         `interconnect I/O bytes`="delta_interconnect_io_bytes"
                       ),
                       selected="1"),
           textAreaInput("addlFilter", "Filter:", rows=3)
    ),
    column(3,
           selectizeInput("category", "break down by column:", choices=NULL, options=list(create=TRUE)),
           textInput("categoryExpr", "transform breakdown column (optional):"),
           numericInput("topN", "Number of top N values to keep", 5)
    ),
    column(3,
           selectInput("palette", "Color palette", rownames(brewer.pal.info), selected='Set2'),
           radioButtons("resolution", "resolution", choices=c('minutes'='mi', 'hours'='hh24', 'days'='dd'), inline=TRUE),
           radioButtons("radPlotRange", "Plot range:", inline=TRUE,choices=c('hour', 'day', 'week', 'month', 'all', 'custom')),
           conditionalPanel(condition="input.radPlotRange == 'custom'",
                            column(6,                               
                                   dateInput("startDate", "Start date", value=Sys.Date()-1)
                            ),
                            column(6,
                                   selectInput("startTime", "Time", choices=paste0(sprintf('%02d', seq(0, 23, 1)), ':00')
                                   )
                            ),
                            column(6,                              
                                   dateInput("endDate", "End date", value=Sys.Date()+1)
                            ),
                            column(6,
                                   selectInput("endTime", "Time", choices=paste0(sprintf('%02d', seq(0, 23, 1)), ':00')
                                   )
                            )
           )
    )
    #    column(3,
    #    ),
    #    column(3, style="margin-top: 25px;",
    #    )
  ),
  # fluidRow(
  #    column(12,
  #           )
  #  ),
  #
  fluidRow(
    column(4),
    column(4
    ),
    column(4)
  ),
  fluidRow(
    column(12,
           plotlyOutput("ashPlot")
    )
  )
)