#!/usr/bin/env python
"""Test module for mhsaddosif.py

Assumes a standard ReconOS reference design (i.e. from edk-base) in 
addOSIFTestCase.mhs as input and tests adding 1 to 8 OSIFs."""

import reconos.testing, unittest, os

class addOSIFTestCase(unittest.TestCase):
	
	pwd = None
	
	def setUp(self):
		# change to mhsaddosif directory
		self.pwd = os.getcwd()
		os.chdir(os.path.dirname(os.path.abspath(__file__)))
	def tearDown(self):
		# return to previous directory
		os.chdir(self.pwd)
	def addNOSIF(self, n):
		reconos.testing.checkScriptOutput('mhsaddosif.py addOSIFTestCase.mhs ' + str(n), 'addOSIFTestCase_' + str(n) + '.stdout', 'addOSIFTestCase_' + str(n) + '.stderr')
	def testAdd1OSIF(self):
		self.addNOSIF(1)
	def testAdd2OSIF(self):
		self.addNOSIF(2)
	def testAdd3OSIF(self):
		self.addNOSIF(3)
	def testAdd4OSIF(self):
		self.addNOSIF(4)
	def testAdd5OSIF(self):
		self.addNOSIF(5)
	def testAdd6OSIF(self):
		self.addNOSIF(6)
	def testAdd7OSIF(self):
		self.addNOSIF(7)
	def testAdd8OSIF(self):
		self.addNOSIF(8)
	
# create test suite with all tests
suite = unittest.makeSuite(addOSIFTestCase)

if __name__ == "__main__":
	unittest.main()
	