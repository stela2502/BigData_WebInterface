use strict;
use warnings;

use BigData_Webinterface;

my $app = BigData_Webinterface->apply_default_middlewares(BigData_Webinterface->psgi_app);
$app;

