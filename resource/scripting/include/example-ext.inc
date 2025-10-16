/**
 * Adds two numbers.
 * @param a The first number.
 * @param b The second number.
 * @return  The result of a + b.
 */
native int AddNums(int a, int b);

public Extension __ext_example_ext = 
{
	name = "Sample Extension",
	file = "example-ext.ext",
#if defined AUTOLOAD_EXTENSIONS
	autoload = 1,
#else
	autoload = 0,
#endif
#if defined REQUIRE_EXTENSIONS
	required = 1,
#else
	required = 0,
#endif
};
