package de.upb.reconos.grasp.gui;

public class HTMLView {
	protected String header;
	protected Object object;
	
	public HTMLView(String header, Object obj){
		this.header = header;
		object = obj;
	}
	
	public String toString(){
		return "<html>" + header + object + "</html>";
	}
	
	public Object getObject(){ return object; }
}
