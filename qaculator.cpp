#ifdef HAVE_QACULATOR

#include <Calculator.h>

static bool firstEnter = true;

extern "C" int qaculate(const char *expr)
{
	int n;
	bool overflow = false;
	if ( firstEnter )
	{
		new Calculator();
	}
	EvaluationOptions eo;
	MathStructure result = CALCULATOR->calculate(expr, eo);

	n = result.number().intValue(&overflow);
	if ( overflow )
	{
		n = 0;
	}

	firstEnter = false;

	return n;
}

#endif
