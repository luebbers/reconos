package de.upb.reconos.grasp.physics;


import java.io.Serializable;

import de.upb.reconos.grasp.math.Vector2d;


public class MassPoint implements Serializable {

	private static final long serialVersionUID = 1L;
	public double mass;
	public double friction;
	public Vector2d position;
	public Vector2d velocity;
	public Vector2d acceleration;
	
	public MassPoint(double x, double y){
		mass = 1;
		friction = 0.9;
		position = new Vector2d(x,y);
		velocity = new Vector2d();
		acceleration = new Vector2d();
	}
	
	public void update(double dt){
		velocity.setX((velocity.getX() + acceleration.getX()*dt)*friction);
		velocity.setY((velocity.getY() + acceleration.getY()*dt)*friction);
		if(velocity.length() < 0.25) velocity.set(0,0);
		position.setX(position.getX() + velocity.getX()*dt);
		position.setY(position.getY() + velocity.getY()*dt);
		acceleration.set(0,0);
	}
	
	public void addForce(double fx, double fy){
		acceleration.setX(acceleration.getX() + fx/mass);
		acceleration.setY(acceleration.getY() + fy/mass);
	}
}
