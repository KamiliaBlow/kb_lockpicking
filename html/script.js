const resourceName = GetParentResourceName();

const sounds = {
    pinup: new Audio('sounds/pinup.mp3'),
    sping: new Audio('sounds/sping.mp3'),
    podsechka: new Audio('sounds/podsechka.mp3'),
    success: new Audio('sounds/pin_succes.mp3'),
    lockpick_succes: new Audio('sounds/lockpick_succes.mp3'),
    pin_fail: new Audio('sounds/pin_fail.mp3'),
    broken: new Audio('sounds/lockpick_broken.mp3')
};

let userControls = {
    MoveLeft: 'ArrowLeft',
    MoveRight: 'ArrowRight',
    PickPin: 'Space',
    LockPin: 'KeyE',
    Exit: 'Backspace'
};

function playBrokenAnimation() {
    const pick = document.getElementById('lockpick');
    const head = document.getElementById('pick-head');
    
    if (!pick || !head) return;

    pick.style.backgroundImage = "url('textures/Lockpick_broken.png')";

    head.style.display = 'block';
    head.style.opacity = '1';
    head.style.transition = 'none';
    head.style.transform = 'translate(0, 0) rotate(0deg)';
    
    const startPosBottom = 45;
    const jumpHeight = 40;

    head.style.bottom = startPosBottom + 'px';

    setTimeout(() => {
        head.style.transition = 'bottom 0.2s ease-out';
        head.style.bottom = (startPosBottom + jumpHeight) + 'px';
    }, 10);

    setTimeout(() => {
        head.style.transition = 'transform 0.2s linear';
        head.style.transform = 'rotate(360deg)';
    }, 250);

    setTimeout(() => {
        const randomX = (Math.random() * 40) - 20;
        const randomRotation = Math.random() * 720;
        
        head.style.transition = 'all 0.3s ease-in';
        head.style.bottom = startPosBottom + 'px';
        head.style.transform = `translate(${randomX}px, 0) rotate(${randomRotation}deg)`;
    }, 500);
}

function playSound(name) {
    if (sounds[name]) {
        const clone = sounds[name].cloneNode();
        clone.volume = 0.5; 
        if (name === 'broken') {
             setTimeout(() => {
                 playBrokenAnimation();
                 clone.play().catch(e => console.log("Broken sound play error:", e));
             }, 50);
        } else {
            clone.play().catch(e => console.log("Audio play error:", e));
        }
    }
}

window.addEventListener('message', function(event) {
    const data = event.data;

    if (data.type === 'openLockpick') {
        const lockBody = document.getElementById('lock-body');
        lockBody.innerHTML = ''; 
        const container = document.getElementById('container');
        const bgLayer = document.getElementById('bg-layer'); 

        if(!container) return;
        
        if(data.controls) userControls = data.controls;
        
        const pinPositions = [62, 113, 162, 212, 264];

        data.pins.forEach((pin, index) => {
            const pinEl = document.createElement('div');
            pinEl.id = `pin-${index}`;
            pinEl.className = 'pin';
            if (pin.type === 2) {
                pinEl.classList.add('locked');
            }
            lockBody.appendChild(pinEl);

            const springEl = document.createElement('div');
            springEl.id = `spring-${index}`;
            springEl.className = 'spring';
            springEl.style.left = pinPositions[index] + 'px';

            if (pin.type === 2) {
                springEl.style.height = '53px';

                springEl.style.transition = 'none';
            } else {
                springEl.style.height = '100px';
                springEl.style.transition = 'height 0.2s ease-out';
            }

            lockBody.appendChild(springEl);
        });
		
		setTimeout(() => {
            const springs = document.querySelectorAll('.spring');
            springs.forEach(s => s.style.transition = 'height 0.2s ease-out');
        }, 100);

        moveLockpick(0);
        
        container.style.display = 'block';
        bgLayer.style.display = 'block'; 
    } 
    else if (data.type === 'movePick') {
        moveLockpick(data.position);
    } 
    else if (data.type === 'updatePin') {
        updatePinState(data.index, data.state, data.duration, data.riseDuration);
    } 
    else if (data.type === 'playSound') {
        playSound(data.sound);
    }
    else if (data.type === 'ui_close') {
        const container = document.getElementById('container');
        const bgLayer = document.getElementById('bg-layer');
        const pick = document.getElementById('lockpick');
        const head = document.getElementById('pick-head');

        if(container) container.style.display = 'none';
        if(bgLayer) bgLayer.style.display = 'none'; 

        if(pick) {
            pick.style.backgroundImage = "url('textures/Lockpick.png')";
        }
        if(head) head.style.display = 'none';
    }
    else if (data.type === 'closeLockpick') {
        const container = document.getElementById('container');
        const bgLayer = document.getElementById('bg-layer');
        
        if(container) container.style.display = 'none';
        if(bgLayer) bgLayer.style.display = 'none'; 
        
        const pick = document.getElementById('lockpick');
        const head = document.getElementById('pick-head');
        if(pick) pick.style.backgroundImage = "url('textures/Lockpick.png')";
        if(head) head.style.display = 'none';

        fetch(`https://${resourceName}/close`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify({})
        });
    }
});

document.addEventListener('keydown', function(event) {
    const container = document.getElementById('container');
    if (!container || container.style.display !== 'block') return;

    let action = null;
    
    if (event.code === userControls.MoveLeft) action = 'left';
    else if (event.code === userControls.MoveRight) action = 'right';
    else if (event.key === 'Enter' || event.code === userControls.PickPin) action = 'pick';
    else if (event.code === userControls.LockPin) action = 'lock';
    else if (event.code === userControls.Exit) action = 'exit';

    if (action) {
        if (action === 'pick') {
            playSound('pinup');
        }

        fetch(`https://${resourceName}/handleInput`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify({ action: action })
        });
    }
});

function moveLockpick(index) {
    const positions = [62, 113, 162, 212, 264];
    const pick = document.getElementById('lockpick');
    if (pick && index >= 0 && positions.length) {
        pick.style.left = positions[index] + 'px';
        pick.style.bottom = '-90px'; 
        pick.style.transition = 'bottom 0.1s ease';
    }
}

function updatePinState(index, state, duration, riseDuration) {
    const pin = document.getElementById(`pin-${index}`);
    const spring = document.getElementById(`spring-${index}`);
    const pick = document.getElementById('lockpick');
    
    if (!pin) return;

    pin.classList.remove('up', 'locked', 'falling');

    if (state === 'up') {
        const rise = riseDuration ? riseDuration : 0.2;
        pin.style.transition = `bottom ${rise}s ease-out`;
        pin.classList.add('up');

        if (spring) {
            spring.style.transition = `height ${rise}s ease-out`;
            spring.style.height = '53px';
            playSound('sping');
        }

        if (pick) {
            pick.style.transition = `bottom ${rise}s ease-out`;
            pick.style.bottom = '-55px'; 
        }

    } 
    else if (state === 'locked') {
        pin.style.transition = 'bottom 0.2s ease';
        pin.classList.add('locked');

        if (spring) {
            spring.style.transition = 'height 0.2s ease';
            spring.style.height = '53px';
        }

        if (pick) {
            pick.style.transition = 'bottom 0.2s ease';
            pick.style.bottom = '-90px'; 
        }

    } 
    else if (state === 'down') {
        const fall = duration ? duration : 0.2;
        pin.style.transition = `bottom ${fall}s ease-in`;

        if (spring) {
            spring.style.transition = `height ${fall}s ease-in`;
            spring.style.height = '100px';
        }

        if (pick) {
            pick.style.transition = `bottom ${fall}s ease-in`;
            pick.style.bottom = '-90px'; 
        }
    }
}