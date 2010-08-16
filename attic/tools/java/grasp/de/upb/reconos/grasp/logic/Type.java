package de.upb.reconos.grasp.logic;

public class Type {
	public String name;
	private Library library;
	
	public Type(Library lib, String name){
		this.name = name;
		library = lib;
	}
	
	public Library getLibrary(){
		return library;
	}
	
	public String toString(){
		return name;
	}
}
