package de.upb.reconos.gui;

public class Vector2d{

	public static double distance(Vector2d a, Vector2d b){
		double dx = a.x - b.x;
		double dy = a.y - b.y;
		return Math.sqrt(dx*dx + dy*dy);
	}
	
	public static Vector2d sub(Vector2d a, Vector2d b){
		return new Vector2d(a.x - b.x, a.y - b.y);
	}

	public static Vector2d add(Vector2d a, Vector2d b){
		return new Vector2d(a.x + b.x, a.y + b.y);
	}
	
	private double x,y;
	
	public double getX() { return x; }
	public double getY() { return y; }
	public void setX(double x) {
		//if(x != x){
		//	throw new RuntimeException();
		//}
		this.x = x;
	}
	public void setY(double y) {
		//if(y != y){
		//	throw new RuntimeException();
		//}
		this.y = y;
	}
	
	public Vector2d(){}
	public Vector2d(double x, double y){ this.x = x; this.y = y; }
	public Vector2d(Vector2d v){ x = v.x; y = v.y; }
	
	public void add(Vector2d v){ x += v.x; y += v.y; }
	public void add(double x, double y) { this.x += x; this.y += y; }
	public void sub(Vector2d v){ x -= v.x; y -= v.y; }
	public void mul(double s){ x *= s; y *= s; }
	public void set(double x, double y){ this.x = x; this.y = y; }
	public void set(Vector2d v){ this.x = v.x; this.y = v.y; }
	public double length(){ return Math.sqrt(x*x + y*y); }
	public void setLength(double l){
		mul(l/length());
		if(l != l) throw new RuntimeException();
		if(x != x || y != y){
			randomize();
			setLength(l);
		}
	}
	public void randomize(){
		x = Math.random()*2 - 1;
		y = Math.random()*2 - 1;
	}
	
	public String toString(){
		return "(" + x + "," + y + ")";
	}
}