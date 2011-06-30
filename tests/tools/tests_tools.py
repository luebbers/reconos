#!/usr/bin/env python

import unittest, mhsaddosif.test, mhsaddthread.test

if __name__ == "__main__":
	
	suite = unittest.TestSuite((mhsaddosif.test.suite, mhsaddthread.test.suite))
	
	runner = unittest.TextTestRunner()
	runner.run(suite)