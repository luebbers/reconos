package de.upb.reconos.fpga;

import java.awt.Color;

public class ColumnRessource {
	public int slice_y_min;
	public int slice_y_max;
	public int slice_x;
	public boolean busmacro_permit;
	public boolean display;
	private int x;
	private int y;
	private String name;
	public Color color;
	
	public ColumnRessource(){}
	public ColumnRessource(String name, int a, int b, int k, int x, int y){
		slice_y_min = a; slice_y_max = b; this.slice_x = k;
		this.x = x;
		this.y = y;
		this.name = name;
		busmacro_permit = false;
		display = false;
		color = new Color(128,128,128);
	}
	public void setCoordinates(int x, int y){
		this.x = x;
		this.y = y;
	}
	
	public int getX() {
		return x;
	}
	public int getY() {
		return y;
	}
	
	public String toString(){
		return name + ": X" + x + "Y" + y;
	}
	
	public String getName(){
		return name;
	}
}
