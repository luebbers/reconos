package de.upb.reconos.grasp.gui;

import de.upb.reconos.grasp.logic.Function;

public class HTMLFunctionView extends HTMLView {
	
	public HTMLFunctionView(String header, Function obj){
		super(header, obj);
	}
	
	public String toString(){
		return "<html>" + header + ((Function)object).toHTML() + "</html>";
	}
	
	public Object getObject(){ return object; }
}
