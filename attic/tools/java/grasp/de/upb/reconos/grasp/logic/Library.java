package de.upb.reconos.grasp.logic;

import java.util.Vector;

public class Library implements Comparable {
	private String name;
	private Vector<Type> types;
	private Vector<Function> functions;
	
	public Library(String name){
		this.name = name;
		types = new Vector<Type>();
		functions = new Vector<Function>();
	}

	public void addType(Type t){
		types.add(t);
	}
	
	public void addFunction(Function f){
		functions.add(f);
	}
	
	public Vector<Function> getFunctions() {
		return functions;
	}

	public String getName() {
		return name;
	}

	public Vector<Type> getTypes() {
		return types;
	}
	
	public Type getType(String name){
		for(Type t : types){
			if(t.name.equals(name)) return t;
		}
		return null;
	}
	
	public String toString() { return getName(); }
	
	public int compareTo(Object o) {
		return getName().compareTo(o.toString());
	}
}
