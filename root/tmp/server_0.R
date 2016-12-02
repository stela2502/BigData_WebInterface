## the strage var names are to not interfere with user defined variable names
LoGfIlE <- '/home/med-sal/git_Projects/BigData_WebInterface/root/tmp/LUNBIO00000000000003/scripts/med-sal_automatic_commands.R'
LoCkFiLe <- '/home/med-sal/git_Projects/BigData_WebInterface/root/tmp/0.input.lock'
InFiLe <- '/home/med-sal/git_Projects/BigData_WebInterface/root/tmp/0.input.R'
setwd( '/home/med-sal/git_Projects/BigData_WebInterface/root/tmp/LUNBIO00000000000003/output/' )
system( paste('touch', LoGfIlE) )
identifyMe <- function () { print ( 'path /home/med-sal/git_Projects/BigData_WebInterface/root/tmp/LUNBIO00000000000003/ on port 0') }
if ( file.exists('.RData')) { load('.RData') }
server <- function(){
  while(TRUE){
        if ( file.exists(InFiLe) ) {
                while ( file.exists( LoCkFiLe ) ) {
                        Sys.sleep( 2 )
                }
                system( paste('cat', InFiLe, '>>', LoGfIlE ))
                tFilE <- file(LoGfIlE,'a')
                sink(tFilE, type = 'output')
                sink(tFilE, type = 'message')
                try ( { source( InFiLe )} )
                sink(type = 'output')
                sink(type = 'message')
                close(tFilE)
                file.remove( InFiLe )
        }
        Sys.sleep(2)
  }
}
server()
