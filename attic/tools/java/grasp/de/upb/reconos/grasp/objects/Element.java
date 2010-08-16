package de.upb.reconos.grasp.objects;


import java.awt.Graphics2D;
import java.io.Serializable;
import java.util.HashSet;
import java.util.Set;

import de.upb.reconos.grasp.interfaces.Animated;
import de.upb.reconos.grasp.interfaces.Drawable;
import de.upb.reconos.grasp.math.Vector2d;


public abstract class Element implements Drawable, Animated, Serializable {
	public World world;
	private Set<Element> required;
	private Set<Element> enabled;
	
	public Element(World world){
		this.world = world;
		required = new HashSet<Element>();
		enabled = new HashSet<Element>();
	}
	
	protected void requires(Element e){
		if(e == null) throw new RuntimeException();
		required.add(e);
		e.enabled.add(this);
	}
	
	protected void disconnect(Element e){
		if(enabled.contains(e)){
			e.dissolve();
			enabled.remove(e);
		}
	}
	
	public void dissolve(){
		world.removeElement(this);
		Set<Element> en = new HashSet<Element>(enabled);
		Set<Element> re = new HashSet<Element>(required);
		required.clear();
		enabled.clear();
		
		for(Element e : en){
			e.dissolve();
		}
		for(Element e : re){
			e.enabled.remove(this);
		}
	}
	
	public abstract void applyForce();
	public abstract void update(double dt);
	public abstract void draw(Graphics2D g2d);
	public abstract Vector2d getPosition();
}
