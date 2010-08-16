package de.upb.reconos.fpga;

import java.awt.Color;

import de.upb.reconos.layout.editor.Range;

public class BlockRessource {
	public Range range;
	private String name;
	public boolean busmacro_permit;
	public boolean display;
	public Color color;
	
	public BlockRessource(String name, Range r){
		this.range = r;
		this.name = name;
		busmacro_permit = false;
		display = false;
		color = new Color(188,188,188);
	}
	
	public String getName(){
		return name;
	}
}