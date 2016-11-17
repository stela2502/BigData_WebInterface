logfile <- '/home/stefan/git/BigData_WebInterface/root/tmp/LUNBIO00000000000002/scripts/med-sal_automatic_commands.R'
infile <- '/home/stefan/git/BigData_WebInterface/root/tmp/0.input.R'
system( paste('touch', logfile) )
server <- function(){
  while(TRUE){
        if ( file.exists(infile) ) {
                while ( file.exists( paste(infile,'log', sep='.' ) ) ) {
                        Sys.sleep( 2 )
                }
                system( paste('cat', infile, '>>', logfile ))
                capture.output(source( infile ), file= logfile, append =T, type='output' )
                file.remove( infile )
        }
        Sys.sleep(2)
  }
}
server()
