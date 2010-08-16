package de.upb.reconos.grasp.io;


import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.Vector;

import de.upb.reconos.grasp.logic.Function;
import de.upb.reconos.grasp.logic.Library;
import de.upb.reconos.grasp.logic.Type;


public class LibraryReader {
	
	public Map<String, Library> libraries;
	
	public LibraryReader(){
		libraries = new HashMap<String, Library>();
	}
	
	public Type getType(Library current, String s){
		System.err.println("getType: " + s);
		if(s.contains(".")){
			String t[] = s.split("\\.");
			Library lib = libraries.get(t[0]);
			return lib.getType(t[1]);
		}
		return current.getType(s);
	}
	
	public void read(String filename) throws IOException {
		FileReader fin = new FileReader(filename);
		BufferedReader br = new BufferedReader(fin);
		
		Library currentLib = null;
		int n = 0;
		while(br.ready()){
			String line = br.readLine();
			n++;
			
			if(line.startsWith("library")){
				if(currentLib != null){
					libraries.put(currentLib.getName(), currentLib);
				}
				try{
					String name = line.split(" ")[1];
					currentLib = new Library(name);
				} catch (IndexOutOfBoundsException ex){
					throw new ParseException(n,"illegal library definition");
				}
			}
			if(line.startsWith("type")){
				if(currentLib == null){
					throw new ParseException(n, "type outside library definition");
				}
				try{
					String name = line.split(" ")[1];
					if(currentLib.getType(name) != null){
						throw new ParseException(n,"redefinition of type "
								+ currentLib.getName() + "." + name);
					}
					currentLib.addType(new Type(currentLib, name));
				} catch (IndexOutOfBoundsException ex){
					throw new ParseException(n,"illegal library definition");
				}
			}
			if(line.startsWith("function")){
				if(currentLib == null){
					throw new ParseException(n, "function outside library definition");
				}
				
				String s[] = line.split(" ", 3);
				String name = s[1];
				
				s = s[2].split("<<");
				
				String inputs[] = s[0].split(",");
				String outputs[] = s[1].split(",");
				
				Function f = new Function(currentLib, name);
				
				for(String param : inputs){
					String p[] = param.trim().split(" ");
					String tname = p[0].split("\\[")[0];
					
					Type t = getType(currentLib, tname);
					if(t == null){
						throw new ParseException(n,"unknown type: " + tname);
					}
					f.addInputParameter(t, p[1]);
				}
				for(String param : outputs){
					String p[] = param.trim().split(" ");
					String tname = p[0].split("\\[")[0];
					Type t = getType(currentLib, tname);
					if(t == null){
						throw new ParseException(n,"unknown type: " + tname);
					}
					f.addOutputParameter(t, p[1]);
				}
				
				currentLib.addFunction(f);
			}
		}
		if(currentLib != null){
			libraries.put(currentLib.getName(), currentLib);
		}
	}
	
	public void write(){
		for(String name : libraries.keySet()){
			System.out.println("library " + name);
			for(Type t : libraries.get(name).getTypes()){
				System.out.println("type " + t);
			}
			for(Function f : libraries.get(name).getFunctions()){
				System.out.println("function " + f);
			}
			System.out.println();
		}
	}
	
	public static void main(String[] a){
		LibraryReader r = new LibraryReader();
		try {
			r.read("/home/andreas/workspace/graphys/stdlib.bar");
		} catch (IOException e) {
			e.printStackTrace();
		}
		r.write();
	}
	
	public Vector<Library> getLibraries(){
		return new Vector<Library>(libraries.values());
	}
}
