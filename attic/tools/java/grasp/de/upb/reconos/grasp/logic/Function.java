package de.upb.reconos.grasp.logic;

import java.util.Vector;

public class Function {
	private String name;
	private Library library;
	private Vector<FormalParameter> inputs;
	private Vector<FormalParameter> outputs;
	
	public class FormalParameter {
		public Type type;
		public String name;
		
		public FormalParameter(Type t, String name){
			type = t;
			this.name = name;
		}
		
		public String toString(){
			return "" + type + " " + name;
		}
	}
	
	public Function(Library lib, String name){
		this.name = name;
		library = lib;
		inputs = new Vector<FormalParameter>();
		outputs = new Vector<FormalParameter>();
	}

	public Vector<FormalParameter> getInputs() {
		return inputs;
	}

	public String getName() {
		return name;
	}

	public Library getLibrary() {
		return library;
	}
	
	public Vector<FormalParameter> getOutputs() {
		return outputs;
	}
	
	public void addInputParameter(Type t, String name){
		inputs.add(new FormalParameter(t,name));
	}
	
	public void addOutputParameter(Type t, String name){
		outputs.add(new FormalParameter(t,name));
	}
	
	public String toHTML(){
		String result = "<b>" + name + "</b> ";
		if(outputs.size() > 0){
			result += outputs.get(0);
		}
		for(int i = 1; i < outputs.size(); i++){
			result += ", " + outputs.get(i);
		}
		
		result += " <b>&lt;&lt;</b> ";
		
		if(inputs.size() > 0){
			result += inputs.get(0);
		}
		for(int i = 1; i < inputs.size(); i++){
			result += ", " + inputs.get(i);
		}
		return result;
	}
	
	public String toString(){
		String result = name + " ";
		if(outputs.size() > 0){
			result += outputs.get(0);
		}
		for(int i = 1; i < outputs.size(); i++){
			result += ", " + outputs.get(i);
		}
		
		result += " << ";
		
		if(inputs.size() > 0){
			result += inputs.get(0);
		}
		for(int i = 1; i < inputs.size(); i++){
			result += ", " + inputs.get(i);
		}
		return result;
	}
}
