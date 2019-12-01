-- title: procedural animated gecko
-- author: lincerely
-- desc:   ref: https://twitter.com/TheRujiK/status/969581641680195585
-- script: lua
-- input: mouse

t=0

IK = {}
function IK:new(x, y)
	local t = setmetatable({}, {__index = IK})
	t.x = x
	t.y = y
	t.len = 0
	return t
end

function IK:newChild(len, angleMin, angleMax)
	local t = setmetatable({}, {__index = IK})
	t.len = len
	t.parent = self
	t.x = t.parent.x + len
	t.y = t.parent.y

	if not angleMin then angleMin = 0 end
	if not angleMax then angleMax = math.pi * 2 end
	t.angleRange = {min=angleMin, max=angleMax}
	return t
end

function IK:show()
	circ(self.x, self.y, 1, 7)
	if self.parent then
		--circb(self.parent.x, self.parent.y, 2, 8)
		--line(self.x, self.y, self.parent.x, self.parent.y, 8)

		if self.angleRange then
			local globalAngle = math.atan2(self.parent.y-self.y, self.parent.x-self.x)
			local angleMax = self.angleRange.max
			local mx = self.x + math.cos(angleMax + globalAngle) * 5
			local my = self.y + math.sin(angleMax + globalAngle) * 5
			line(self.x, self.y, mx, my, 9)

			local angleMin = self.angleRange.min
			local mx = self.x + math.cos(angleMin + globalAngle) * 5
			local my = self.y + math.sin(angleMin + globalAngle) * 5
			line(self.x, self.y, mx, my, 12)
		end
	end
end

function Reach(tailX, tailY, targetX, targetY, len)
	local dx = targetX - tailX
	local dy = targetY - tailY
	local scale = len / math.sqrt(dx*dx + dy*dy)
	local tailX = targetX - dx * scale
	local tailY = targetY - dy * scale
	return tailX, tailY
end

function updateIKs(IKs, stx, sty, etx, ety)
	if stx and sty then
		local tx, ty = stx, sty
		for k,j in pairs(IKs) do
			j.x, j.y = Reach(j.x, j.y, tx, ty, j.len)
			tx, ty = j.x, j.y
		end
	end

	if etx and ety then
		IKs[#IKs].x, IKs[#IKs].y = etx, ety
		local tx, ty = etx, ety
		for i = #IKs-1, 1, -1 do
			local j = IKs[i]
			local prevLen = IKs[i+1].len
			j.x, j.y = Reach(j.x, j.y, tx, ty, prevLen)
			tx, ty = j.x, j.y
		end
	end
end

function lerp(a, b, t)
	return a + (b - a) * t
end

function distance(p0, p1)
	local dx,dy = p0.x - p1.x, p0.y - p1.y
	return math.sqrt(dx*dx+dy*dy)
end

function LocalPosition(p0, pFoward, len, angle)
	local dx,dy = pFoward.x - p0.x, pFoward.y - p0.y
	local dist = math.sqrt(dx*dx+dy*dy)
	dx,dy = dx*len/dist, dy*len/dist
	local cosA = math.cos(angle)
	local sinA = math.sin(angle)
	return cosA*dx - sinA*dy, sinA*dx+cosA*dy
end

function DrawGeckoLeg(legIK)
	local gecko_leg ={4,2,2,3}
	local gecko_leg_color = 7
	local foot_color = 7
	local fill_n = 4

	for k,v in pairs(legIK) do
		if k == 1 then --Plam
			circ(v.x, v.y, gecko_leg[1], foot_color)
		else
			for i=0, fill_n do
				local x = lerp(legIK[k-1].x, v.x, i/fill_n)
				local y = lerp(legIK[k-1].y, v.y, i/fill_n)
				local r = lerp(gecko_leg[k], gecko_leg[k+1], i/fill_n)
				circ(x, y, r, gecko_leg_color)
			end
		end
	end
end

function DrawGeckoBody(bodyIK)
	local gecko_body={4,9,6,7, 7,5,5,4, 3,2,2,2, 1,1,0}
	local gecko_body_color = 7
	local fill_n = 10

	for k,v in pairs(bodyIK) do
		if k == 1 then
			circ(v.x, v.y, gecko_body[k], 7)
		else
			for i=0,fill_n do
				local x = lerp(bodyIK[k-1].x, v.x, i/fill_n)
				local y = lerp(bodyIK[k-1].y, v.y, i/fill_n)
				local r = lerp(gecko_body[k-1], gecko_body[k], i/fill_n)
				circ(x, y, r, 7)
			end
		end
	end
end

function DrawGeckoEye(bodyIK)
	local dx, dy = LocalPosition(bodyIK[2], bodyIK[1], 8, 45* math.pi/180)
	circ(bodyIK[2].x+dx, bodyIK[2].y+dy, 2, 0)
	local dx, dy = LocalPosition(bodyIK[2], bodyIK[1], 8, -45 *math.pi/180)
	circ(bodyIK[2].x+dx, bodyIK[2].y+dy, 2, 0)
end

function DrawGeckoIKs(bodyIK, legs)
	for _, l in pairs(legs) do
		if l.leftUp then circ(l.leftTarget.x, l.leftTarget.y, 3, 5) end
		if l.rightUp then circ(l.rightTarget.x, l.rightTarget.y, 3, 6) end

		for k, v in pairs(l.leftIK) do
			--print(tostring(k), v.x-8, v.y-8, 5)
			v:show()
		end
		for k, v in pairs(l.rightIK) do
			--print(tostring(k), v.x-8, v.y-8, 6)
			v:show()
		end
	end

	for k, v in pairs(bodyIK) do 
		--print(tostring(k), v.x-8, v.y-8, 15)
		v:show()
	end
end

function UpdateLegs(legs)
		
	local prevLeft, prevRight = false, false

	for k, l in pairs(legs) do
		if #legs > 1 then
			if k == 1 then 
				prevLeft, prevRight = legs[#legs].leftUp, legs[#legs].rightUp
			else
				prevLeft, prevRight = legs[k-1].leftUp, legs[k-1].rightUp
			end
		end

		if prevRight or l.leftUp then
			local dx, dy = LocalPosition(l.baseJoint, l.forwardJoint, l.stepLength, l.legAngle)
			l.leftTarget={x=l.baseJoint.x + dx, y=l.baseJoint.y + dy}
			local tx=lerp(l.leftIK[1].x, l.leftTarget.x, l.legSpeed)
			local ty=lerp(l.leftIK[1].y, l.leftTarget.y, l.legSpeed)
			updateIKs(l.leftIK, tx, ty, l.baseJoint.x, l.baseJoint.y)
			if distance(l.leftTarget, l.leftIK[1]) <= 2 then 
				l.leftUp = false
			end
		else 
			updateIKs(l.leftIK, l.leftTarget.x, l.leftTarget.y, l.baseJoint.x, l.baseJoint.y)
			if not l.rightUp and distance(l.leftTarget, l.baseJoint) > l.stepLength then 
				l.leftUp = true
			end
		end

		local force = .5

		if l.leftUp then 
			local dx,dy = LocalPosition(l.baseJoint, l.leftIK[1], force, math.pi/2)
			l.baseJoint.x = l.baseJoint.x + dx
			l.baseJoint.y = l.baseJoint.y + dy
		end

		if prevLeft or l.rightUp then
			local dx, dy = LocalPosition(l.baseJoint, l.forwardJoint, l.stepLength, -l.legAngle)
			l.rightTarget={x=l.baseJoint.x + dx, y=l.baseJoint.y + dy}
			local tx= lerp(l.rightIK[1].x, l.rightTarget.x, l.legSpeed)
			local ty= lerp(l.rightIK[1].y, l.rightTarget.y, l.legSpeed)
			updateIKs(l.rightIK, tx, ty, l.baseJoint.x, l.baseJoint.y)
			if distance(l.rightTarget, l.rightIK[1]) <= 2 then 
				l.rightUp = false
			end
		else
			updateIKs(l.rightIK, l.rightTarget.x, l.rightTarget.y, l.baseJoint.x, l.baseJoint.y)
			if not l.leftUp and distance(l.rightTarget, l.baseJoint) > l.stepLength then 
				l.rightUp = true
			end
		end


		if l.rightUp then 
			local dx,dy = LocalPosition(l.baseJoint, l.rightIK[1], force, -math.pi/2)
			l.baseJoint.x = l.baseJoint.x + dx
			l.baseJoint.y = l.baseJoint.y + dy
		end

	end
end

function rad(angle)
	return angle * math.pi / 180
end

bodyIK={}
legs={}
target={}
rightTarget={}
movSpeed = .01
targetSpeed = .01
isDebug=false
hideGraphic=false

function init()
	bodyIK[1] = IK:new(20, 136/2, 0) 
	for i = 1, 10 do
		bodyIK[i+1] = bodyIK[i]:newChild(15)
	end

	legs = {}
	legs[1]= {
		stepLength=20,
		legLength=10,
		legSpeed=.3,
		legAngle=40*math.pi/180,
		jointCnt=2,
		baseJoint=bodyIK[3],
		forwardJoint=bodyIK[2],
	}
	legs[2]= {
		stepLength=20,
		legLength=10,
		legSpeed=.3,
		legAngle=40*math.pi/180,
		jointCnt=2,
		baseJoint=bodyIK[5],
		forwardJoint=bodyIK[4],
	}

	for k,l in pairs(legs) do 
		l.leftIK={}
		l.leftIK[1] = IK:new(l.baseJoint.x, l.baseJoint.y)
		l.rightIK={}
		l.rightIK[1] = IK:new(l.baseJoint.x, l.baseJoint.y)
		l.leftIK[2] = l.leftIK[1]:newChild(l.legLength, rad(-30), rad(0))
		l.rightIK[2] = l.rightIK[1]:newChild(l.legLength, rad(-30), rad(0))
		l.leftIK[3] = l.leftIK[2]:newChild(l.legLength, rad(-30), rad(30))
		l.rightIK[3] = l.rightIK[2]:newChild(l.legLength, rad(-30), rad(30))

		local dx, dy = LocalPosition(l.baseJoint, l.forwardJoint, l.stepLength, -l.legAngle)
		l.rightTarget = {x=l.baseJoint.x + dx, y=l.baseJoint.y + dy}
		dx, dy = LocalPosition(l.baseJoint, l.forwardJoint, l.stepLength, l.legAngle)
		l.leftTarget={x=l.baseJoint.x + dx, y=l.baseJoint.y + dy}
	end
end

function TIC()

	if btnp(4) then isDebug = not isDebug end
	if btnp(5) then hideGraphic = not hideGraphic end

	local mx, my, left = mouse()
	if not left then
		mx = (math.sin(t * targetSpeed)+1)*100 + 20 
		my = (math.cos(t * targetSpeed)+1)*60 + 8
	end

	local flooredLegs = 0
	local totalLegs = #legs * 2
	for _, l in pairs(legs) do
		if not l.leftUp then flooredLegs = flooredLegs + 1 end
		if not l.rightUp then flooredLegs = flooredLegs + 1 end
	end

	target.x = lerp(bodyIK[1].x, mx, movSpeed * flooredLegs/totalLegs)
	target.y = lerp(bodyIK[1].y, my, movSpeed * flooredLegs/totalLegs)
	updateIKs(bodyIK, target.x, target.y)
	UpdateLegs(legs)

	t = t + 1

	--draw
	cls(0)
	print(movSpeed * flooredLegs/totalLegs)
	print("[CLICK] MOVE", 0, 106, 1)
	print("[z] BONES", 0, 116, 1)
	print("[x] GRAPHICS", 0, 126, 1)
	circ(mx, my, 3, 15)
	if not hideGraphic then
		for _, l in pairs(legs) do
			DrawGeckoLeg(l.leftIK)
			DrawGeckoLeg(l.rightIK)
		end
		DrawGeckoBody(bodyIK)
		DrawGeckoEye(bodyIK)
	end
	if isDebug then DrawGeckoIKs(bodyIK, legs) end
end

init()
