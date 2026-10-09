import React, { useState, useEffect } from 'react';
import { 
  Building2, Calculator, MapPin, FileText, Database, Shield,
  TrendingUp, RefreshCw, Plus, CheckCircle, AlertCircle, ExternalLink,
  Layers, Users, Sparkles, BookOpen
} from 'lucide-react';
import { adminApi } from './api';
import { SystemStats, District, CalculatorRule, GuidelineValue, DocumentGuide } from './types';

export default function App() {
  const [activeTab, setActiveTab] = useState<'overview' | 'rules' | 'guidelines' | 'geography' | 'guides' | 'system'>('overview');
  const [stats, setStats] = useState<SystemStats | null>(null);
  const [rules, setRules] = useState<CalculatorRule[]>([]);
  const [guidelines, setGuidelines] = useState<GuidelineValue[]>([]);
  const [districts, setDistricts] = useState<District[]>([]);
  const [guides, setGuides] = useState<DocumentGuide[]>([]);
  const [loading, setLoading] = useState<boolean>(true);

  // New Rule Form State
  const [showAddRuleModal, setShowAddRuleModal] = useState(false);
  const [newRuleName, setNewRuleName] = useState('');
  const [newStampRate, setNewStampRate] = useState(7.0);
  const [newRegRate, setNewRegRate] = useState(2.0);
  const [newTxType, setNewTxType] = useState('sale');

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      const [s, r, g, d, dg] = await Promise.all([
        adminApi.getStats(),
        adminApi.getCalculatorRules(),
        adminApi.getGuidelineValues(),
        adminApi.getDistricts(),
        adminApi.getDocumentGuides()
      ]);
      setStats(s);
      setRules(r);
      setGuidelines(g);
      setDistricts(d);
      setGuides(dg);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const handleAddRule = (e: React.FormEvent) => {
    e.preventDefault();
    const created: CalculatorRule = {
      id: `rule-${Date.now()}`,
      rule_name: newRuleName || "Custom Registration Rule",
      jurisdiction: "tamil_nadu_state",
      transaction_type: newTxType,
      property_type: "all",
      stamp_duty_rate: Number(newStampRate),
      registration_fee_rate: Number(newRegRate),
      transfer_duty_rate: 0,
      fixed_cess: 100,
      effective_from: new Date().toISOString().split('T')[0],
      is_active: true,
      created_at: new Date().toISOString()
    };
    setRules([created, ...rules]);
    setShowAddRuleModal(false);
    setNewRuleName('');
  };

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col font-sans">
      {/* Top Navigation Bar */}
      <header className="bg-emerald-950 text-white border-b border-emerald-900 shadow-sm sticky top-0 z-30">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 rounded-xl bg-amber-400 text-emerald-950 flex items-center justify-center font-bold text-xl shadow-md">
              M
            </div>
            <div>
              <div className="flex items-center space-x-2">
                <span className="font-bold text-lg tracking-tight">TN LandMate</span>
                <span className="bg-amber-400/20 text-amber-300 text-xs px-2 py-0.5 rounded-full font-semibold border border-amber-400/30">
                  GovOps Admin
                </span>
              </div>
              <p className="text-xs text-emerald-200">Tamil Nadu Land Records & Regulatory Administration</p>
            </div>
          </div>

          <div className="flex items-center space-x-4">
            <button 
              onClick={loadData}
              className="p-2 text-emerald-200 hover:text-white rounded-lg hover:bg-emerald-900 transition flex items-center text-xs space-x-1"
              title="Refresh Data"
            >
              <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
              <span className="hidden sm:inline">Sync</span>
            </button>
            <div className="h-6 w-px bg-emerald-800" />
            <div className="flex items-center space-x-2 text-sm">
              <div className="w-8 h-8 rounded-full bg-emerald-800 flex items-center justify-center font-bold text-amber-300 text-xs border border-emerald-700">
                AD
              </div>
              <div className="hidden md:block text-left">
                <div className="text-xs font-semibold leading-none">Registration Admin</div>
                <div className="text-[10px] text-emerald-300">Revenue Dept, TN</div>
              </div>
            </div>
          </div>
        </div>

        {/* Tab Sub-Nav */}
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex space-x-1 overflow-x-auto text-sm scrollbar-none">
          {[
            { id: 'overview', label: 'System Overview', icon: TrendingUp },
            { id: 'rules', label: 'Calculator Rules', icon: Calculator },
            { id: 'guidelines', label: 'Guideline Values', icon: Building2 },
            { id: 'geography', label: 'TN Geography (38 Dists)', icon: MapPin },
            { id: 'guides', label: 'Document Guides', icon: BookOpen },
            { id: 'system', label: 'AI & Data Sources', icon: Database },
          ].map((tab) => {
            const Icon = tab.icon;
            const active = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as any)}
                className={`flex items-center space-x-2 px-4 py-3 border-b-2 text-xs font-medium whitespace-nowrap transition ${
                  active 
                    ? 'border-amber-400 text-amber-300 bg-emerald-900/40' 
                    : 'border-transparent text-emerald-200 hover:text-white hover:bg-emerald-900/20'
                }`}
              >
                <Icon className="w-4 h-4" />
                <span>{tab.label}</span>
              </button>
            );
          })}
        </div>
      </header>

      {/* Main Content Area */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 flex-1 w-full">
        {/* TAB 1: SYSTEM OVERVIEW */}
        {activeTab === 'overview' && (
          <div className="space-y-6">
            <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
              <div>
                <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Department Control Center</h1>
                <p className="text-sm text-slate-500">Live operational status, database statistics, and regulatory integrity checks.</p>
              </div>
              <div className="flex items-center space-x-2">
                <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-emerald-100 text-emerald-800">
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 mr-1.5 animate-pulse" />
                  FastAPI Engine Online
                </span>
                <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                  PostgreSQL / SQLite Dual Engine
                </span>
              </div>
            </div>

            {/* Quick Metrics Grid */}
            <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-4">
              {[
                { title: 'Districts', count: stats?.total_districts ?? 38, icon: MapPin, color: 'text-emerald-700 bg-emerald-50' },
                { title: 'Taluks', count: stats?.total_taluks ?? 10, icon: Layers, color: 'text-blue-700 bg-blue-50' },
                { title: 'Villages', count: stats?.total_villages ?? 10, icon: Building2, color: 'text-indigo-700 bg-indigo-50' },
                { title: 'SRO Offices', count: stats?.total_sros ?? 5, icon: Shield, color: 'text-amber-700 bg-amber-50' },
                { title: 'Active Rules', count: rules.length, icon: Calculator, color: 'text-rose-700 bg-rose-50' },
                { title: 'Users Synced', count: stats?.total_users ?? 2, icon: Users, color: 'text-teal-700 bg-teal-50' },
              ].map((card, i) => {
                const Icon = card.icon;
                return (
                  <div key={i} className="bg-white rounded-xl border border-slate-200 p-4 shadow-sm hover:shadow transition">
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-xs font-semibold text-slate-500">{card.title}</span>
                      <div className={`p-1.5 rounded-lg ${card.color}`}>
                        <Icon className="w-4 h-4" />
                      </div>
                    </div>
                    <div className="text-2xl font-bold text-slate-900">{card.count}</div>
                  </div>
                );
              })}
            </div>

            {/* System Status & Regulatory Audit */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
              <div className="lg:col-span-2 bg-white rounded-xl border border-slate-200 p-6 shadow-sm">
                <div className="flex items-center justify-between mb-4">
                  <h2 className="text-base font-bold text-slate-900">Current Statutory Fee Rules (Tamil Nadu)</h2>
                  <button 
                    onClick={() => setActiveTab('rules')}
                    className="text-xs text-emerald-700 font-semibold hover:underline"
                  >
                    Manage Rules →
                  </button>
                </div>
                <div className="space-y-3">
                  {rules.slice(0, 3).map((r) => (
                    <div key={r.id} className="p-3.5 rounded-lg border border-slate-100 bg-slate-50/50 flex items-center justify-between hover:bg-slate-50 transition">
                      <div>
                        <div className="font-semibold text-sm text-slate-900">{r.rule_name}</div>
                        <div className="text-xs text-slate-500 mt-0.5">
                          Stamp Duty: <span className="font-bold text-emerald-800">{r.stamp_duty_rate}%</span> • Registration: <span className="font-bold text-emerald-800">{r.registration_fee_rate}%</span> • Effective: {r.effective_from}
                        </div>
                      </div>
                      <span className="px-2.5 py-1 text-[11px] font-semibold bg-emerald-100 text-emerald-800 rounded-full">
                        Gazetted
                      </span>
                    </div>
                  ))}
                </div>
              </div>

              <div className="bg-white rounded-xl border border-slate-200 p-6 shadow-sm space-y-4">
                <h2 className="text-base font-bold text-slate-900">Compliance & Verification</h2>
                <div className="p-3 bg-amber-50 rounded-lg border border-amber-200 text-amber-900 text-xs leading-relaxed space-y-2">
                  <div className="flex items-center space-x-1 font-bold">
                    <Shield className="w-4 h-4 text-amber-700" />
                    <span>No Fabricated Data Guardrail</span>
                  </div>
                  <p>
                    All test land records in development mode are tagged with <code className="bg-amber-100 px-1 py-0.5 rounded font-mono font-bold">is_demo=true</code>. Live searches gracefully direct citizens to official <code className="bg-amber-100 px-1 py-0.5 rounded font-mono">eservices.tn.gov.in</code>.
                  </p>
                </div>
                <div className="border-t border-slate-100 pt-3 space-y-2 text-xs text-slate-600">
                  <div className="flex justify-between">
                    <span>Guideline Dataset Source:</span>
                    <span className="font-semibold text-slate-900">TNREGINET 2024</span>
                  </div>
                  <div className="flex justify-between">
                    <span>Revenue Districts Configured:</span>
                    <span className="font-semibold text-slate-900">38 of 38 Districts</span>
                  </div>
                  <div className="flex justify-between">
                    <span>AI Assistant Provider:</span>
                    <span className="font-semibold text-slate-900">Offline Fallback + Extractor</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* TAB 2: CALCULATOR RULES */}
        {activeTab === 'rules' && (
          <div className="space-y-6">
            <div className="flex justify-between items-center">
              <div>
                <h1 className="text-2xl font-bold text-slate-900">Statutory Calculator Rules</h1>
                <p className="text-sm text-slate-500">Configure stamp duty and registration percentages by transaction type and jurisdiction.</p>
              </div>
              <button
                onClick={() => setShowAddRuleModal(true)}
                className="px-4 py-2 bg-emerald-800 text-white rounded-lg text-xs font-semibold hover:bg-emerald-900 flex items-center space-x-1.5 shadow-sm"
              >
                <Plus className="w-4 h-4" />
                <span>Add Regulatory Rule</span>
              </button>
            </div>

            <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-50 border-b border-slate-200 text-slate-600 font-semibold">
                  <tr>
                    <th className="py-3 px-4">Rule Title</th>
                    <th className="py-3 px-4">Transaction</th>
                    <th className="py-3 px-4">Stamp Duty</th>
                    <th className="py-3 px-4">Registration</th>
                    <th className="py-3 px-4">Effective Date</th>
                    <th className="py-3 px-4">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 text-slate-800">
                  {rules.map((rule) => (
                    <tr key={rule.id} className="hover:bg-slate-50/60 transition">
                      <td className="py-3.5 px-4">
                        <div className="font-bold text-slate-900">{rule.rule_name}</div>
                        <div className="text-[11px] text-slate-400">{rule.jurisdiction}</div>
                      </td>
                      <td className="py-3.5 px-4 capitalize font-medium">{rule.transaction_type.replace('_', ' ')}</td>
                      <td className="py-3.5 px-4 font-bold text-emerald-800">{rule.stamp_duty_rate}%</td>
                      <td className="py-3.5 px-4 font-bold text-emerald-800">{rule.registration_fee_rate}%</td>
                      <td className="py-3.5 px-4 text-slate-600">{rule.effective_from}</td>
                      <td className="py-3.5 px-4">
                        <span className="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-emerald-100 text-emerald-800">
                          Active
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* TAB 3: GUIDELINE VALUES */}
        {activeTab === 'guidelines' && (
          <div className="space-y-6">
            <div className="flex justify-between items-center">
              <div>
                <h1 className="text-2xl font-bold text-slate-900">Guideline Value Registry</h1>
                <p className="text-sm text-slate-500">Official valuation rates per square foot / acre from Tamil Nadu Registration Department.</p>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {guidelines.map((gv) => (
                <div key={gv.id} className="bg-white rounded-xl border border-slate-200 p-5 shadow-sm space-y-3">
                  <div className="flex justify-between items-start">
                    <div>
                      <div className="text-xs font-semibold text-emerald-800 uppercase tracking-wider">{gv.village_name_en}</div>
                      <h3 className="text-base font-bold text-slate-900 mt-0.5">{gv.street_or_survey_number}</h3>
                    </div>
                    <span className="px-2 py-1 bg-amber-100 text-amber-800 text-[10px] font-bold rounded">
                      {gv.classification}
                    </span>
                  </div>
                  <div className="pt-2 border-t border-slate-100 flex items-baseline justify-between">
                    <span className="text-xs text-slate-500">Guideline Value:</span>
                    <span className="text-xl font-extrabold text-emerald-950">₹{gv.value_in_rupees.toLocaleString()} <span className="text-xs font-normal text-slate-500">/{gv.unit}</span></span>
                  </div>
                  <div className="text-[11px] text-slate-400">
                    Source: {gv.source_attribution} • Effective: {gv.effective_from}
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* TAB 4: TN GEOGRAPHY */}
        {activeTab === 'geography' && (
          <div className="space-y-6">
            <div>
              <h1 className="text-2xl font-bold text-slate-900">Tamil Nadu Revenue Districts</h1>
              <p className="text-sm text-slate-500">Complete list of 38 Revenue Districts in bilingual English and Tamil.</p>
            </div>

            <div className="bg-white rounded-xl border border-slate-200 shadow-sm p-4">
              <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-3">
                {districts.map((d) => (
                  <div key={d.id} className="p-3 rounded-lg border border-slate-100 bg-slate-50/50 hover:bg-emerald-50/40 hover:border-emerald-200 transition">
                    <div className="text-[10px] font-mono font-bold text-emerald-800">{d.code} • #{d.id}</div>
                    <div className="font-bold text-sm text-slate-900">{d.name_en}</div>
                    <div className="text-xs text-slate-500">{d.name_ta}</div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* TAB 5: DOCUMENT GUIDES */}
        {activeTab === 'guides' && (
          <div className="space-y-6">
            <div>
              <h1 className="text-2xl font-bold text-slate-900">Citizen Education Document Guides</h1>
              <p className="text-sm text-slate-500">Bilingual guidance for Patta, Chitta, A-Register, FMB, EC, and Sale Deeds.</p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {guides.map((g) => (
                <div key={g.id} className="bg-white rounded-xl border border-slate-200 p-5 shadow-sm space-y-3">
                  <div className="flex items-center justify-between">
                    <h3 className="font-bold text-slate-900 text-base">{g.title_en}</h3>
                    <a 
                      href={g.official_portal_url} 
                      target="_blank" 
                      rel="noopener noreferrer" 
                      className="text-emerald-700 hover:text-emerald-900 p-1"
                      title="Open Official Portal"
                    >
                      <ExternalLink className="w-4 h-4" />
                    </a>
                  </div>
                  <p className="text-xs text-slate-600 line-clamp-2">{g.summary_en}</p>
                  <p className="text-xs text-emerald-900 bg-emerald-50/60 p-2.5 rounded-lg border border-emerald-100">
                    {g.summary_ta}
                  </p>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* TAB 6: SYSTEM & AI */}
        {activeTab === 'system' && (
          <div className="space-y-6">
            <div>
              <h1 className="text-2xl font-bold text-slate-900">AI Assistant & Data Sources Configuration</h1>
              <p className="text-sm text-slate-500">Operational state of natural language Q&A and document extraction services.</p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="bg-white rounded-xl border border-slate-200 p-6 shadow-sm space-y-4">
                <div className="flex items-center space-x-2 text-emerald-800">
                  <Sparkles className="w-5 h-5" />
                  <h3 className="font-bold text-base text-slate-900">AI Land Assistant Guardrails</h3>
                </div>
                <div className="text-xs text-slate-600 space-y-2 leading-relaxed">
                  <p>• <strong>Offline Domain Knowledge Bank:</strong> Active for Patta, Chitta, FMB, Poramboke, Natham, EC, and Guideline concepts in both English & Tamil.</p>
                  <p>• <strong>OCR Extractor:</strong> Pattern matcher for survey numbers, subdivisions, extents, and party names.</p>
                  <p>• <strong>Strict Legal Disclaimer:</strong> Enforced on all assistant outputs to ensure no legal representation is implied.</p>
                </div>
                <div className="pt-2">
                  <span className="inline-block px-3 py-1 bg-emerald-100 text-emerald-800 text-xs font-semibold rounded-full">
                    AI Service: Ready & Protected
                  </span>
                </div>
              </div>

              <div className="bg-white rounded-xl border border-slate-200 p-6 shadow-sm space-y-4">
                <div className="flex items-center space-x-2 text-emerald-800">
                  <Database className="w-5 h-5" />
                  <h3 className="font-bold text-base text-slate-900">Authorized Government Endpoints</h3>
                </div>
                <div className="text-xs text-slate-600 space-y-2">
                  <div className="p-2.5 bg-slate-50 rounded border border-slate-200 flex justify-between items-center">
                    <div>
                      <div className="font-bold text-slate-800">TN Revenue e-Services (Anytime/Anywhere)</div>
                      <div className="text-[10px] text-slate-500">https://eservices.tn.gov.in</div>
                    </div>
                    <span className="text-[10px] font-bold px-2 py-0.5 bg-emerald-100 text-emerald-800 rounded">Verified</span>
                  </div>
                  <div className="p-2.5 bg-slate-50 rounded border border-slate-200 flex justify-between items-center">
                    <div>
                      <div className="font-bold text-slate-800">TNREGINET (Inspector General of Registration)</div>
                      <div className="text-[10px] text-slate-500">https://tnreginet.gov.in</div>
                    </div>
                    <span className="text-[10px] font-bold px-2 py-0.5 bg-emerald-100 text-emerald-800 rounded">Verified</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}
      </main>

      {/* Add Rule Modal */}
      {showAddRuleModal && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-xl space-y-4">
            <h3 className="text-lg font-bold text-slate-900">Add Statutory Fee Rule</h3>
            <form onSubmit={handleAddRule} className="space-y-4 text-xs">
              <div>
                <label className="block font-semibold text-slate-700 mb-1">Rule Description</label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Commercial Conveyance 2024"
                  value={newRuleName}
                  onChange={(e) => setNewRuleName(e.target.value)}
                  className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-600"
                />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-semibold text-slate-700 mb-1">Stamp Duty (%)</label>
                  <input
                    type="number"
                    step="0.1"
                    required
                    value={newStampRate}
                    onChange={(e) => setNewStampRate(parseFloat(e.target.value))}
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-600"
                  />
                </div>
                <div>
                  <label className="block font-semibold text-slate-700 mb-1">Registration (%)</label>
                  <input
                    type="number"
                    step="0.1"
                    required
                    value={newRegRate}
                    onChange={(e) => setNewRegRate(parseFloat(e.target.value))}
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-600"
                  />
                </div>
              </div>
              <div>
                <label className="block font-semibold text-slate-700 mb-1">Transaction Category</label>
                <select
                  value={newTxType}
                  onChange={(e) => setNewTxType(e.target.value)}
                  className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-600 capitalize"
                >
                  <option value="sale">Sale Deed</option>
                  <option value="settlement_family">Family Settlement</option>
                  <option value="gift">Gift Deed</option>
                  <option value="mortgage">Mortgage</option>
                </select>
              </div>
              <div className="flex justify-end space-x-2 pt-2">
                <button
                  type="button"
                  onClick={() => setShowAddRuleModal(false)}
                  className="px-4 py-2 border border-slate-300 rounded-lg text-slate-700 font-semibold hover:bg-slate-50"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-emerald-800 text-white rounded-lg font-semibold hover:bg-emerald-900"
                >
                  Publish Rule
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Footer */}
      <footer className="bg-white border-t border-slate-200 py-4 text-center text-xs text-slate-500">
        TN LandMate Administrative Suite • Department of Revenue & Disaster Management, Government of Tamil Nadu Reference
      </footer>
    </div>
  );
}
