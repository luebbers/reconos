#!/usr/bin/python
# **************************
# Get thread names
# **************************
import sys, os, re
from string import Template

# *****************************************************************************
# Internal Variables
# *****************************************************************************
# Filename definitions
contentsFile="contents.txt"
symbolFile="symbols.txt"
headerFile="header.h"

# Symbol table extraction tool
symbolDump="powerpc-eabi-nm"	

# String templates for header generation
structDef = """
// Node type
typedef struct {
  int id;
  int val;
  char name[20];
} tnode_t;\n\n"""

funcDef = """
int find_val (tnode_t ls[], int lookup_id)
{
    int i = 0;
    int ret_val = 0;

    int cur_id = ls[i].id;
    int cur_val = ls[i].val;

    // Loop until terminating node is hit
    while(cur_val != 0xffffffff)
    {
        // Check for a match
        if (cur_id == lookup_id) {
            ret_val = cur_val;
            break;
        }

        // Go to next node
        i++;

        // Update ID and Val
        cur_id = ls[i].id;
        cur_val = ls[i].val;
    }

    return ret_val;
}\n\n"""

id_template = Template('lookup[$ind].id = $id;\n')
val_template = Template('lookup[$ind].val = $val;\n\n')

# *****************************************************************************
# Main program
# *****************************************************************************

def main():
    # Check command line argument
    num_args = len(sys.argv)
    if num_args > 2:
        # Save filename
        EXEC_FILE = sys.argv[1]

        # Get all of the source file names
        source_filename = sys.argv[2:]
    else:
        # Insufficient number of args, exit with error
        print "Incorrect argument usage!! Aborting..."
        print "Correct usage :\n    ./get_thread_names.py <executable> <srcFile0> ... <srcFileN>\n"
        sys.exit(2)

    # *****************************************************************************
    # Create a "contents" file that contains all source files
    # *****************************************************************************
    # Create a new file that contains contents of all source files
    status = os.system('rm -f '+contentsFile+' && touch '+contentsFile)
    
    # Fill contents file with the contents of each file
    for fname in source_filename:
        status = os.system('cat '+fname+' >> '+contentsFile)

    # *****************************************************************************
    # Find all of the thread create calls
    # *****************************************************************************
    # Read contents file
	infile = open(contentsFile,"r")
	lines = infile.readlines()
    infile.close()

    print "--BEGIN--"
    print "Looking for thread create calls..."

    # Delete contents file (no longer needed)
    status = os.system('rm -f '+contentsFile)
    
    # Search for regex
    threadNames = []
    index = 0
    for line in lines:
        m = re.search('hthread_create(.*)',line)
        if m:
            # Add thread name (split on commas, and take 3rd arg)
            threadNames.append(m.group().split(',')[2])

    # Check to see if any threads were found
    if (not threadNames):
        print "No thread creation calls were found!!!"
        sys.exit(3)
    else:
        print "Processing thread names..."

    # *****************************************************************************
    # Extract symbol table from the executable
    # *****************************************************************************        
    print "Generating symbol table..."

    status = os.system(symbolDump+' '+EXEC_FILE+' > '+symbolFile)

    # *****************************************************************************
    # Extract symbol values for each thread name
    # *****************************************************************************        
    # Read symbol file
    infile = open(symbolFile,"r")
    lines = infile.readlines()
    infile.close()

    # Delete symbol file (no longer needed)
    status = os.system('rm -f '+symbolFile)

    # Search for thread names on each line
    symbolDict = {}
    for line in lines:
        for name in threadNames:
            m = line.find(name)
            if m != -1:
                # Extract symbol and place in dictionary
                symbol = line[:8]   # Symbols are 32-bit (or 8 hex) numbers
                symbolDict[name] = symbol 

    # Check to see if the dictionary has any valid items
    if (not symbolDict): 
        print "No thread names were found in the symbol table!!!"
        sys.exit(4)

    # *****************************************************************************
    # Create a header file that associates thread names with symbols
    # *****************************************************************************        

    # Create a header file
    outfile = open(headerFile,"w")

    # Add in struct def
    outfile.write(structDef)
    outfile.write(funcDef)

    # Add in array declaration (size + 1 extra for terminating node)
    outfile.write("// Array of nodes\n")
    outfile.write("tnode_t lookup[%d] = {\n" % (len(symbolDict) + 1))
    
    # Display results
    for (i,(tname,loc)) in enumerate(symbolDict.items()): 
        print '\t'+tname+'----'+loc
        outfile.write('  {0x'+loc+', '+str(i)+', \"'+tname+'\\n\"}, // '+tname+'\n')

    # Add in a terminating node
    outfile.write('  {0xffffffff, 0xffffffff,\"termination\\n\"} // Termination node\n')
    outfile.write('};\n\n')

    # Close file
    outfile.close()

    print "--COMPLETE--"

   
if __name__ == "__main__":
    main()	
