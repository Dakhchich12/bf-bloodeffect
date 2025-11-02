let activeEffects = 0;
const maxEffects = 3;

window.addEventListener('message', (event) => {
    const data = event.data;
    if (data.action === 'showBlood') showBloodEffect(data);
});

function showBloodEffect(data) {
    if (activeEffects >= maxEffects) return;

    activeEffects++;

    const container = document.getElementById('bloodContainer');
    const blood = document.createElement('div');
    blood.className = 'blood-splatter';

    const baseSize = 320; // slightly bigger base for realism
    const size = baseSize * (0.7 + (data.intensity || 0.5) * 0.6);

    const centerX = 0.5 + (data.offsetX || 0);
    const centerY = 0.5 + (data.offsetY || 0);
    const rotation = Math.floor(Math.random() * 360);
    const fadeDuration = data.fadeTime || 800;
    const totalDuration = data.duration || 3000;

    // Apply main styles
    blood.style.width = `${size}px`;
    blood.style.height = `${size}px`;
    blood.style.left = `${centerX * 100}%`;
    blood.style.top = `${centerY * 100}%`;
    blood.style.opacity = data.opacity || 0.6;
    blood.style.transform = `translate(-50%, -50%) rotate(${rotation}deg)`;
    blood.style.zIndex = 1000 + activeEffects; // ensure proper stacking

    const img = document.createElement('img');
    img.src = 'images/blood.png';
    img.alt = 'blood splatter';
    img.draggable = false;

    blood.appendChild(img);
    container.appendChild(blood);

    // fade-out + cleanup
    setTimeout(() => {
        blood.style.transition = `opacity ${fadeDuration}ms ease-out`;
        blood.style.opacity = '0';

        setTimeout(() => {
            if (blood.parentNode) blood.parentNode.removeChild(blood);
            activeEffects = Math.max(0, activeEffects - 1);
        }, fadeDuration);
    }, Math.max(500, totalDuration - fadeDuration));
}

// Clean up all effects on unload
window.addEventListener('beforeunload', () => {
    const container = document.getElementById('bloodContainer');
    while (container.firstChild) container.removeChild(container.firstChild);
    activeEffects = 0;
});
