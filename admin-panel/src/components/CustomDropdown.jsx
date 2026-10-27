import React, { useState, useRef, useEffect } from 'react';
import { ChevronDown, Check } from 'lucide-react';

export default function CustomDropdown({
  value,
  onChange,
  options = [],
  placeholder = 'Select option...',
  className = '',
  style = {},
  triggerStyle = {},
  menuStyle = {},
  disabled = false,
  size = 'md'
}) {
  const [isOpen, setIsOpen] = useState(false);
  const containerRef = useRef(null);

  useEffect(() => {
    function handleClickOutside(event) {
      if (containerRef.current && !containerRef.current.contains(event.target)) {
        setIsOpen(false);
      }
    }
    if (isOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    }
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [isOpen]);

  // Normalize options to { value, label }
  const normalizedOptions = options.map(opt => {
    if (typeof opt === 'object' && opt !== null) {
      return { value: opt.value ?? opt.id ?? opt.name, label: opt.label ?? opt.name ?? String(opt.value) };
    }
    return { value: opt, label: String(opt) };
  });

  const selectedOption = normalizedOptions.find(opt => String(opt.value) === String(value));
  const displayLabel = selectedOption ? selectedOption.label : placeholder;

  const isSmall = size === 'sm';

  return (
    <div
      ref={containerRef}
      className={`custom-dropdown-container ${className}`}
      style={{
        position: 'relative',
        display: 'inline-block',
        width: '100%',
        ...style
      }}
    >
      <button
        type="button"
        disabled={disabled}
        onClick={() => !disabled && setIsOpen(prev => !prev)}
        style={{
          width: '100%',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          gap: 8,
          background: 'var(--bg-input, #18181b)',
          border: isOpen ? '1px solid #FF9500' : '1px solid var(--border-color, rgba(255, 255, 255, 0.12))',
          borderRadius: isSmall ? 8 : 'var(--radius-sm, 10px)',
          padding: isSmall ? '6px 10px' : '10px 14px',
          color: selectedOption ? '#ffffff' : 'var(--text-muted, #a1a1aa)',
          fontSize: isSmall ? '12px' : '13.5px',
          fontWeight: 600,
          cursor: disabled ? 'not-allowed' : 'pointer',
          boxShadow: isOpen ? '0 0 0 2px rgba(255, 149, 0, 0.25)' : 'none',
          transition: 'all 0.18s ease',
          outline: 'none',
          ...triggerStyle
        }}
      >
        <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
          {displayLabel}
        </span>
        <ChevronDown
          size={isSmall ? 14 : 16}
          style={{
            color: isOpen ? '#FF9500' : 'var(--text-muted, #a1a1aa)',
            transform: isOpen ? 'rotate(180deg)' : 'rotate(0deg)',
            transition: 'transform 0.2s ease',
            flexShrink: 0
          }}
        />
      </button>

      {isOpen && (
        <div
          style={{
            position: 'absolute',
            top: 'calc(100% + 4px)',
            left: 0,
            right: 0,
            minWidth: '100%',
            maxHeight: 240,
            overflowY: 'auto',
            background: 'rgba(24, 24, 27, 0.96)',
            backdropFilter: 'blur(20px)',
            WebkitBackdropFilter: 'blur(20px)',
            border: '1px solid rgba(255, 255, 255, 0.15)',
            borderRadius: isSmall ? 8 : 10,
            boxShadow: '0 12px 30px rgba(0, 0, 0, 0.55)',
            padding: 4,
            zIndex: 9999,
            ...menuStyle
          }}
        >
          {normalizedOptions.map((opt) => {
            const isSelected = String(opt.value) === String(value);
            return (
              <div
                key={String(opt.value)}
                onClick={() => {
                  onChange(opt.value);
                  setIsOpen(false);
                }}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  gap: 8,
                  padding: isSmall ? '6px 8px' : '8px 10px',
                  borderRadius: isSmall ? 6 : 8,
                  fontSize: isSmall ? '12px' : '13px',
                  fontWeight: isSelected ? 700 : 500,
                  color: isSelected ? '#FF9500' : '#e4e4e7',
                  background: isSelected ? 'rgba(255, 149, 0, 0.15)' : 'transparent',
                  cursor: 'pointer',
                  transition: 'background 0.15s ease'
                }}
                onMouseEnter={(e) => {
                  if (!isSelected) e.currentTarget.style.background = 'rgba(255, 255, 255, 0.06)';
                }}
                onMouseLeave={(e) => {
                  if (!isSelected) e.currentTarget.style.background = 'transparent';
                }}
              >
                <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                  {opt.label}
                </span>
                {isSelected && <Check size={14} style={{ color: '#FF9500', flexShrink: 0 }} />}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
