require('Vector')

function KinematicEquation(acceleration, velocity, initialPos, time)
    return 0.5 * acceleration * time^2 + velocity * time + initialPos
end