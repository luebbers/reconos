package de.upb.reconos.parser;


public class ConfigNodeType {
	private String keyword;
	private boolean container;
	
	public ConfigNodeType(String keyword){
		this.keyword = keyword;
		container = false;
	}
	
	public ConfigNodeType(String keyword, boolean container){
		this.keyword = keyword;
		this.container = container;
	}
	
	public boolean isContainer() {
		return container;
	}

	public void setContainer(boolean container) {
		this.container = container;
	}

	public String getKeyword() {
		return keyword;
	}
}
