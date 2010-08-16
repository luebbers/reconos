#!/usr/bin/env python
#
# ****************************************************************************
# Author:	Jason Agron
# Purpose:	Implement a stack in python
# ****************************************************************************

class stack:

	def __init__(self):
		# Setup an "empty" stack
		self.stack = []
	
	# Function: push
	def push(self,element):
		self.stack.append(element)
	
	# Function: pop
	def pop(self):
		# Check if stack is empty
		if (len(self.stack) == 0):
			raise "Error", "Cannot pop an empty stack!"
		# Otherwise, pop the top element
		el = self.stack[-1]
		del self.stack[-1]
		return el

	# Function: top
	def top(self):
		# Check if stack is empty
		if (len(self.stack) == 0):
			raise "Error", "Cannot top an empty stack!"
		# Otherwise, return the top element, but leave it on the stack
		return self.stack[-1]
		
	# Function: is_empty
	def is_empty(self):
		return (len(self.stack) == 0)
	
	# Function: num_elements
	def num_elements(self):
		return len(self.stack)
				
	# Function: display
	def display(self):
		print "Top of Stack"
		n = len(self.stack)
		for i in range(n):
			print "Index = "+i+", "+self.stack(n-i)

# Test program
if __name__ == "__main__":
	s = stack()
	if s.num_elements() != 0: raise error
	s.push("hola")
	s.push("shalom")
	if s.is_empty(): raise error
	e = s.pop()	
	if s.is_empty(): raise error
	e = s.pop()	
	if not s.is_empty(): raise error
	print "Test Passed! Stack works"
				
				
				
