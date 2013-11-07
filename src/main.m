int main(int argc, char **argv)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	int ret = UIApplicationMain(argc, argv, @"WiFiApplication", @"WiFiApplication");

	[pool drain];

	return ret;
}
