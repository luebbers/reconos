package de.upb.reconos.grasp.interfaces;

import de.upb.reconos.grasp.physics.ChargedPoint;

public interface ForceField extends Animated {
	public void applyForceToPoint(ChargedPoint p);
}
