#!/usr/bin/env python
"""Test module for mhsaddthread.py

Included tests:

	- adding 1 to 8 threads to MHS files with existing slots
	  Input: addThreadTestCase_1.mhs to _8.mhs

	- adding threads to MHS files without slots
	  Input: addThreadTestCase_noslot.mhs
			-> supposed to fail (with exit code 2)
"""

import reconos.testing, unittest, os

class addThreadTestCase(unittest.TestCase):
	
	pwd = None
	
	def setUp(self):
		# change to mhsaddosif directory
		self.pwd = os.getcwd()
		os.chdir(os.path.dirname(os.path.abspath(__file__)))
	def tearDown(self):
		# return to previous directory
		os.chdir(self.pwd)
	def addThreadsNSlots(self, n):
		reconos.testing.checkScriptOutput('mhsaddthread.py addThreadTestCase_' + str(n) + '.mhs', 'addThreadTestCase_' + str(n) + '.stdout', 'addThreadTestCase_' + str(n) + '.stderr', expectedExitCode=0)
	def addThreadsNSlotsWithThreadClock(self, n):
		reconos.testing.checkScriptOutput('mhsaddthread.py -c OtherClock addThreadTestCase_' + str(n) + '.mhs', 'addThreadTestCaseWithThreadClock_' + str(n) + '.stdout', 'addThreadTestCaseWithThreadClock_' + str(n) + '.stderr', expectedExitCode=0)
	def testAddThreadsNoSlot(self):
		'''Test adding threads without slots present'''
		reconos.testing.checkScriptOutput('mhsaddthread.py addThreadTestCase_noslot.mhs', 'addThreadTestCase_noslot.stdout', 'addThreadTestCase_noslot.stderr', expectedExitCode=2)
	def testAddThreads1Slot(self):
		'''Test adding threads with 1 slot present'''
		self.addThreadsNSlots(1)
	def testAddThreads2Slots(self):
		'''Test adding threads with 2 slots present'''
		self.addThreadsNSlots(2)
	def testAddThreads3Slots(self):
		'''Test adding threads with 3 slots present'''
		self.addThreadsNSlots(3)
	def testAddThreads4Slots(self):
		'''Test adding threads with 4 slots present'''
		self.addThreadsNSlots(4)
	def testAddThreads5Slots(self):
		'''Test adding threads with 5 slots present'''
		self.addThreadsNSlots(5)
	def testAddThreads6Slots(self):
		'''Test adding threads with 6 slots present'''
		self.addThreadsNSlots(6)
	def testAddThreads7Slots(self):
		'''Test adding threads with 7 slots present'''
		self.addThreadsNSlots(7)
	def testAddThreads8Slots(self):
		'''Test adding threads with 8 slots present'''
		self.addThreadsNSlots(8)
	def testAddThreads1SlotWithThreadClock(self):
		'''Test adding threads with 1 slot present and separate thread clock'''
		self.addThreadsNSlotsWithThreadClock(1)
	def testAddThreads2SlotsWithThreadClock(self):
		'''Test adding threads with 2 slots present and separate thread clock'''
		self.addThreadsNSlotsWithThreadClock(2)
	def testAddThreads3SlotsWithThreadClock(self):
		'''Test adding threads with 3 slots present and separate thread clock'''
		self.addThreadsNSlotsWithThreadClock(3)
	def testAddThreads4SlotsWithThreadClock(self):
		'''Test adding threads with 4 slots present and separate thread clock'''
		self.addThreadsNSlotsWithThreadClock(4)
	def testAddThreads5SlotsWithThreadClock(self):
		'''Test adding threads with 5 slots present and separate thread clock'''
		self.addThreadsNSlotsWithThreadClock(5)
	def testAddThreads6SlotsWithThreadClock(self):
		'''Test adding threads with 6 slots present and separate thread clock'''
		self.addThreadsNSlotsWithThreadClock(6)
	def testAddThreads7SlotsWithThreadClock(self):
		'''Test adding threads with 7 slots present and separate thread clock'''
		self.addThreadsNSlotsWithThreadClock(7)
	def testAddThreads8SlotsWithThreadClock(self):
		'''Test adding threads with 8 slots present and separate thread clock'''
		self.addThreadsNSlotsWithThreadClock(8)

	
# create test suite with all tests
suite = unittest.makeSuite(addThreadTestCase)

if __name__ == "__main__":
	unittest.main()
	